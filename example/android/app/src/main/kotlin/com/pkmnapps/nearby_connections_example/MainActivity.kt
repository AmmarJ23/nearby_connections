package com.pkmnapps.nearby_connections_example

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pkmnapps.nearby_connections/notification"
    private val NOTIFICATION_CHANNEL_ID = "nearby_connections_channel"
    private val NOTIFICATION_ID = 1001

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        createNotificationChannel()

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
}
