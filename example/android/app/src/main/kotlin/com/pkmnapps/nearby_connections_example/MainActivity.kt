package com.pkmnapps.nearby_connections_example

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pkmnapps.nearby_connections/notification"
    private val OVERLAY_CHANNEL = "com.pkmnapps.nearby_connections/overlay"
    private val NOTIFICATION_CHANNEL_ID = "nearby_connections_channel"
    private val NOTIFICATION_ID = 1001
    private val OVERLAY_PERMISSION_REQUEST = 1234
    
    companion object {
        private const val TAG = "MainActivity"
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        createNotificationChannel()

        // Notification channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startNotification" -> {
                    @Suppress("UNCHECKED_CAST")
                    val data = call.arguments as Map<String, Any>
                    showNotification(data)
                    result.success(null)
                }
                "updateNotification" -> {
                    @Suppress("UNCHECKED_CAST")
                    val data = call.arguments as Map<String, Any>
                    showNotification(data)
                    result.success(null)
                }
                "stopNotification" -> {
                    cancelNotification()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Overlay channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST)
                            result.success(false)
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "showOverlay" -> {
                    @Suppress("UNCHECKED_CAST")
                    val data = call.arguments as Map<String, Any>
                    showOverlay(data)
                    result.success(null)
                }
                "updateOverlay" -> {
                    @Suppress("UNCHECKED_CAST")
                    val data = call.arguments as Map<String, Any>
                    updateOverlay(data)
                    result.success(null)
                }
                "hideOverlay" -> {
                    hideOverlay()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Nearby Connections"
            val descriptionText = "Status of nearby connections"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showNotification(data: Map<String, Any>) {
        val selfName = data["selfName"] as? String ?: "Me"
        val selfActivity = data["selfActivity"] as? String ?: "Idle"
        val connectedCount = (data["connectedCount"] as? Number)?.toInt() ?: 0
        
        val usersListRaw = data["users"] as? List<*>
        val users = usersListRaw?.mapNotNull { item ->
            if (item is Map<*, *>) {
                mapOf(
                    "name" to (item["name"]?.toString() ?: "Unknown"),
                    "activity" to (item["activity"]?.toString() ?: "Idle")
                )
            } else {
                null
            }
        } ?: emptyList()

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }
        val pendingIntent: PendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("$selfName: $selfActivity")
            .setContentText("Connected: $connectedCount")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setOnlyAlertOnce(true)

        // Use InboxStyle to show list of users
        val inboxStyle = NotificationCompat.InboxStyle()
        inboxStyle.setBigContentTitle("$connectedCount Connected Users")
        
        if (users.isEmpty()) {
            inboxStyle.addLine("No users connected")
        } else {
            users.forEach { user ->
                val name = user["name"] ?: "Unknown"
                val activity = user["activity"] ?: "Idle"
                inboxStyle.addLine("$name: $activity")
            }
        }
        
        builder.setStyle(inboxStyle)

        with(NotificationManagerCompat.from(this)) {
            try {
                notify(NOTIFICATION_ID, builder.build())
            } catch (e: SecurityException) {
                // Handle missing permission
            }
        }
    }

    private fun cancelNotification() {
        with(NotificationManagerCompat.from(this)) {
            cancel(NOTIFICATION_ID)
        }
    }

    private fun showOverlay(data: Map<String, Any>) {
        Log.d(TAG, "showOverlay called")
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_SHOW
            putExtras(extractOverlayData(data))
        }
        startService(intent)
        Log.d(TAG, "Started OverlayService with ACTION_SHOW")
    }

    private fun updateOverlay(data: Map<String, Any>) {
        Log.d(TAG, "updateOverlay called")
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_UPDATE
            putExtras(extractOverlayData(data))
        }
        startService(intent)
        Log.d(TAG, "Started OverlayService with ACTION_UPDATE")
    }

    private fun hideOverlay() {
        Log.d(TAG, "hideOverlay called")
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_HIDE
        }
        startService(intent)
        Log.d(TAG, "Started OverlayService with ACTION_HIDE")
    }

    private fun extractOverlayData(data: Map<String, Any>): android.os.Bundle {
        val bundle = android.os.Bundle()
        
        val selfName = data["selfName"] as? String ?: "Me"
        val selfActivity = data["selfActivity"] as? String ?: "Idle"
        val connectedCount = (data["connectedCount"] as? Number)?.toInt() ?: 0
        
        val usersListRaw = data["users"] as? List<*>
        val users = usersListRaw?.mapNotNull { item ->
            if (item is Map<*, *>) {
                mapOf(
                    "name" to (item["name"]?.toString() ?: "Unknown"),
                    "activity" to (item["activity"]?.toString() ?: "Idle")
                )
            } else {
                null
            }
        } ?: emptyList()

        bundle.putString(OverlayService.EXTRA_SELF_NAME, selfName)
        bundle.putString(OverlayService.EXTRA_SELF_ACTIVITY, selfActivity)
        bundle.putInt(OverlayService.EXTRA_CONNECTED_COUNT, connectedCount)
        
        if (users.isNotEmpty()) {
            bundle.putString(OverlayService.EXTRA_FIRST_USER_NAME, users[0]["name"])
            bundle.putString(OverlayService.EXTRA_FIRST_USER_ACTIVITY, users[0]["activity"])
        }
        
        return bundle
    }
}
