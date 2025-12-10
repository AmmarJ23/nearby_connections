package com.pkmnapps.nearby_connections_example

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.util.Log

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    
    companion object {
        private const val TAG = "OverlayService"
        const val ACTION_SHOW = "SHOW_OVERLAY"
        const val ACTION_UPDATE = "UPDATE_OVERLAY"
        const val ACTION_HIDE = "HIDE_OVERLAY"
        const val EXTRA_SELF_NAME = "selfName"
        const val EXTRA_SELF_ACTIVITY = "selfActivity"
        const val EXTRA_CONNECTED_COUNT = "connectedCount"
        const val EXTRA_FIRST_USER_NAME = "firstUserName"
        const val EXTRA_FIRST_USER_ACTIVITY = "firstUserActivity"
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called with action: ${intent?.action}")
        when (intent?.action) {
            ACTION_SHOW -> showOverlay(intent)
            ACTION_UPDATE -> updateOverlay(intent)
            ACTION_HIDE -> hideOverlay()
            else -> Log.w(TAG, "Unknown action: ${intent?.action}")
        }
        return START_STICKY
    }

    private fun showOverlay(intent: Intent) {
        Log.d(TAG, "showOverlay called")
        if (overlayView != null) {
            Log.d(TAG, "Overlay already exists, updating instead")
            updateOverlay(intent)
            return
        }

        try {
            Log.d(TAG, "Creating overlay view")
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            )

            params.gravity = Gravity.TOP or Gravity.END
            params.x = 16
            params.y = 100

            Log.d(TAG, "Inflating overlay layout")
            overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_widget, null)
            
            // Make overlay draggable
            setupDragging(overlayView!!, params)
            
            Log.d(TAG, "Adding view to WindowManager")
            windowManager?.addView(overlayView, params)
            updateOverlay(intent)
            
            Log.d(TAG, "Overlay view added successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing overlay", e)
        }
    }

    private fun setupDragging(view: View, params: WindowManager.LayoutParams) {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f

        view.setOnTouchListener { v, event ->
            when (event.action) {
                android.view.MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                android.view.MotionEvent.ACTION_MOVE -> {
                    params.x = initialX + (initialTouchX - event.rawX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    windowManager?.updateViewLayout(view, params)
                    true
                }
                else -> false
            }
        }
    }

    private fun updateOverlay(intent: Intent) {
        Log.d(TAG, "updateOverlay called, overlayView exists: ${overlayView != null}")
        overlayView?.let { view ->
            val selfName = intent.getStringExtra(EXTRA_SELF_NAME) ?: "Me"
            val selfActivity = intent.getStringExtra(EXTRA_SELF_ACTIVITY) ?: "Idle"
            val connectedCount = intent.getIntExtra(EXTRA_CONNECTED_COUNT, 0)
            val firstUserName = intent.getStringExtra(EXTRA_FIRST_USER_NAME)
            val firstUserActivity = intent.getStringExtra(EXTRA_FIRST_USER_ACTIVITY)

            Log.d(TAG, "Updating overlay: $selfName - $selfActivity, connected: $connectedCount")

            view.findViewById<TextView>(R.id.overlay_self_name)?.text = selfName
            view.findViewById<TextView>(R.id.overlay_self_activity)?.text = selfActivity
            view.findViewById<TextView>(R.id.overlay_connected_count)?.text = "$connectedCount"
            
            val userContainer = view.findViewById<LinearLayout>(R.id.overlay_user_container)
            if (firstUserName != null && connectedCount > 0) {
                userContainer?.visibility = View.VISIBLE
                view.findViewById<TextView>(R.id.overlay_user_name)?.text = firstUserName
                view.findViewById<TextView>(R.id.overlay_user_activity)?.text = firstUserActivity ?: "Idle"
            } else {
                userContainer?.visibility = View.GONE
            }

            // Update activity icon based on activity type
            val activityIcon = view.findViewById<ImageView>(R.id.overlay_activity_icon)
            val iconRes = when (selfActivity.lowercase()) {
                "idle" -> android.R.drawable.ic_menu_recent_history
                "typing", "typing message", "writing notes" -> android.R.drawable.ic_menu_edit
                "browsing", "browsing home", "browsing photos" -> android.R.drawable.ic_menu_compass
                "viewing messages", "reading messages" -> android.R.drawable.ic_menu_view
                "editing document", "editing profile" -> android.R.drawable.ic_menu_manage
                "filling form" -> android.R.drawable.ic_menu_agenda
                "viewing page" -> android.R.drawable.ic_menu_info_details
                else -> android.R.drawable.ic_menu_help
            }
            activityIcon?.setImageResource(iconRes)
            
            Log.d(TAG, "Overlay updated: $selfName - $selfActivity, connected: $connectedCount")
        }
    }

    private fun hideOverlay() {
        overlayView?.let {
            windowManager?.removeView(it)
            overlayView = null
            Log.d(TAG, "Overlay hidden")
        }
        stopSelf()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        hideOverlay()
    }
}
