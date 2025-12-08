package com.pkmnapps.nearby_connections_example

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL
import com.example.live_activities.LiveActivityManager

class CustomLiveActivityManager(context: Context) :
    LiveActivityManager(context) {
    private val context: Context = context.applicationContext
    private val pendingIntent = PendingIntent.getActivity(
        context, 200, Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    private val remoteViews = RemoteViews(
        context.packageName, R.layout.live_activity
    )

    suspend fun loadImageBitmap(imageUrl: String?): Bitmap? {
        val dp = context.resources.displayMetrics.density.toInt()
        return withContext(Dispatchers.IO) {
            if (imageUrl.isNullOrEmpty()) return@withContext null
            try {
                val url = URL(imageUrl)
                val connection = url.openConnection() as HttpURLConnection
                connection.doInput = true
                connection.connectTimeout = 3000
                connection.readTimeout = 3000
                connection.connect()
                connection.inputStream.use { inputStream ->
                    val originalBitmap = BitmapFactory.decodeStream(inputStream)
                    originalBitmap?.let {
                        val targetSize = 64 * dp
                        val aspectRatio =
                            it.width.toFloat() / it.height.toFloat()
                        val (targetWidth, targetHeight) = if (aspectRatio > 1) {
                            targetSize to (targetSize / aspectRatio).toInt()
                        } else {
                            (targetSize * aspectRatio).toInt() to targetSize
                        }
                        Bitmap.createScaledBitmap(
                            it,
                            targetWidth,
                            targetHeight,
                            true
                        )
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
        }
    }

    private suspend fun updateRemoteViews(
        deviceName: String,
        connectionStatus: String,
        dataReceived: String,
        timestamp: Long,
    ) {
        remoteViews.setTextViewText(R.id.device_name, deviceName)
        remoteViews.setTextViewText(R.id.connection_status, connectionStatus)
        remoteViews.setTextViewText(R.id.data_info, dataReceived)

        val elapsedRealtime = android.os.SystemClock.elapsedRealtime()
        val currentTimeMillis = System.currentTimeMillis()
        val base = elapsedRealtime - (currentTimeMillis - timestamp)

        remoteViews.setChronometer(R.id.connection_time, base, null, true)
    }

    override suspend fun buildNotification(
        notification: Notification.Builder,
        event: String,
        data: Map<String, Any>
    ): Notification {
        val deviceName = data["deviceName"] as? String ?: "Unknown Device"
        val timestamp = data["timestamp"] as? Long ?: System.currentTimeMillis()
        val connectionStatus = data["connectionStatus"] as? String ?: "Disconnected"
        val dataReceived = data["dataReceived"] as? String ?: "No data"

        updateRemoteViews(
            deviceName,
            connectionStatus,
            dataReceived,
            timestamp,
        )

        return notification
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setContentTitle("Nearby Connection: $deviceName")
            .setContentIntent(pendingIntent)
            .setContentText(connectionStatus)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setPriority(Notification.PRIORITY_LOW)
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
    }
}
