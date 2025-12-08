package com.pkmnapps.nearby_connections_example

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.example.live_activities.LiveActivityManager

class CustomLiveActivityManager(context: Context) :
    LiveActivityManager(context) {
    
    companion object {
        private const val TAG = "CustomLiveActivity"
    }

    private val context: Context = context.applicationContext
    private val pendingIntent = PendingIntent.getActivity(
        context, 200, Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    override suspend fun buildNotification(
        notification: Notification.Builder,
        event: String,
        data: Map<String, Any>
    ): Notification {
        try {
            Log.d(TAG, "Building notification for event: $event")
            
            // Create new RemoteViews for each update to avoid state issues
            val remoteViews = RemoteViews(context.packageName, R.layout.live_activity)

            val selfName = data["selfName"]?.toString() ?: "Me"
            val selfActivity = data["selfActivity"]?.toString() ?: "Idle"
            val connectedCount = (data["connectedCount"] as? Number)?.toInt() ?: 0
            
            // Safely extract users list handling potential type mismatches
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

            Log.d(TAG, "Parsed users: ${users.size}")

            // Set self status
            remoteViews.setTextViewText(R.id.self_name, selfName)
            remoteViews.setTextViewText(R.id.self_activity, selfActivity)
            remoteViews.setTextViewText(R.id.connected_count, "Connected: $connectedCount")

            // Reset all user slots to GONE first
            remoteViews.setViewVisibility(R.id.user1_layout, View.GONE)
            remoteViews.setViewVisibility(R.id.user2_layout, View.GONE)
            remoteViews.setViewVisibility(R.id.user3_layout, View.GONE)

            // Populate User 1
            if (users.isNotEmpty()) {
                val user = users[0]
                remoteViews.setTextViewText(R.id.user1_name, user["name"])
                remoteViews.setTextViewText(R.id.user1_activity, user["activity"])
                remoteViews.setViewVisibility(R.id.user1_layout, View.VISIBLE)
            }

            // Populate User 2
            if (users.size > 1) {
                val user = users[1]
                remoteViews.setTextViewText(R.id.user2_name, user["name"])
                remoteViews.setTextViewText(R.id.user2_activity, user["activity"])
                remoteViews.setViewVisibility(R.id.user2_layout, View.VISIBLE)
            }

            // Populate User 3
            if (users.size > 2) {
                val user = users[2]
                remoteViews.setTextViewText(R.id.user3_name, user["name"])
                remoteViews.setTextViewText(R.id.user3_activity, user["activity"])
                remoteViews.setViewVisibility(R.id.user3_layout, View.VISIBLE)
            }

            // Show more indicator if there are more users
            if (users.size > 3) {
                remoteViews.setTextViewText(
                    R.id.more_users_text,
                    "+${users.size - 3} more"
                )
                remoteViews.setViewVisibility(R.id.more_users_text, View.VISIBLE)
            } else {
                remoteViews.setViewVisibility(R.id.more_users_text, View.GONE)
            }

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

        } catch (e: Exception) {
            Log.e(TAG, "Error building notification", e)
            // Fallback to a simple notification if custom view fails
            return notification
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle("Nearby Connections")
                .setContentText("Active")
                .build()
        }
    }
}
