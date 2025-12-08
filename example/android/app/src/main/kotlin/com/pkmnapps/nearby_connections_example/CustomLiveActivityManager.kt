package com.pkmnapps.nearby_connections_example

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
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

    private fun updateRemoteViews(
        selfName: String,
        selfActivity: String,
        connectedCount: Int,
        users: List<Map<String, String>>
    ) {
        // Set self status
        remoteViews.setTextViewText(R.id.self_name, selfName)
        remoteViews.setTextViewText(R.id.self_activity, selfActivity)
        remoteViews.setTextViewText(R.id.connected_count, "Connected: $connectedCount")

        // Clear previous user list
        remoteViews.removeAllViews(R.id.users_container)

        // Add connected users (limit to first 3 for space)
        users.take(3).forEach { user ->
            val userName = user["name"] as? String ?: "Unknown"
            val userActivity = user["activity"] as? String ?: "Idle"
            
            val userView = RemoteViews(context.packageName, R.layout.user_item)
            userView.setTextViewText(R.id.user_name, userName)
            userView.setTextViewText(R.id.user_activity, userActivity)
            
            remoteViews.addView(R.id.users_container, userView)
        }

        // Show more indicator if there are more users
        if (users.size > 3) {
            remoteViews.setTextViewText(
                R.id.more_users_text,
                "+${users.size - 3} more"
            )
            remoteViews.setViewVisibility(R.id.more_users_text, android.view.View.VISIBLE)
        } else {
            remoteViews.setViewVisibility(R.id.more_users_text, android.view.View.GONE)
        }
    }

    override suspend fun buildNotification(
        notification: Notification.Builder,
        event: String,
        data: Map<String, Any>
    ): Notification {
        val selfName = data["selfName"] as? String ?: "Me"
        val selfActivity = data["selfActivity"] as? String ?: "Idle"
        val connectedCount = data["connectedCount"] as? Int ?: 0
        
        @Suppress("UNCHECKED_CAST")
        val users = data["users"] as? List<Map<String, String>> ?: emptyList()

        updateRemoteViews(
            selfName,
            selfActivity,
            connectedCount,
            users
        )

        return notification
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setContentTitle("Nearby Connections")
            .setContentIntent(pendingIntent)
            .setContentText("$connectedCount connected")
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setPriority(Notification.PRIORITY_LOW)
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
    }
}
