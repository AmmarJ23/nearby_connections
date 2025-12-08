# Live Activities Integration for Nearby Connections

This implementation adds Live Activities support to the Nearby Connections example app for Android.

## Features

The live activity notification displays:
- Your current activity status
- Number of connected users
- Connected users and their activity statuses (up to 3 users shown)
- Ongoing notification that updates in real-time

## How It Works

### Flutter/Dart Side

1. **Model** (`lib/models/connection_status_live_activity_model.dart`):
   - Defines the data structure for connection status
   - Includes self status and connected users list

2. **Integration** (`lib/main.dart`):
   - Initializes LiveActivities plugin on app start
   - Creates/updates live activity when:
     - User activity changes
     - Connections are established or lost
     - Remote user status updates are received
   - Automatically manages the notification lifecycle

### Android Side

1. **Custom Live Activity Manager** (`android/app/src/main/kotlin/.../CustomLiveActivityManager.kt`):
   - Extends `LiveActivityManager` from the live_activities plugin
   - Builds the custom notification layout
   - Manages the notification appearance and content

2. **MainActivity** (`android/app/src/main/kotlin/.../MainActivity.kt`):
   - Registers the custom manager with the live_activities plugin

3. **Layout Resources**:
   - `res/layout/live_activity.xml`: Main notification layout
   - `res/layout/user_item.xml`: Individual user item layout
   - `res/drawable/*.xml`: Background shapes and icons
   - `res/values/colors.xml`: Color definitions

## Usage

1. Start advertising or discovering nearby devices
2. Connect to other devices
3. The live activity notification will automatically appear
4. Change your activity status using the activity selection buttons
5. The notification updates automatically to reflect:
   - Your current activity
   - Connected users count
   - Each connected user's activity status

## Requirements

- Android API 26 (Android 8.0) or higher (for notification channels)
- Notification permission granted
- live_activities plugin dependency

## Note

The live activity is implemented as an ongoing notification on Android, which provides similar functionality to iOS Live Activities by showing real-time status updates in the notification area.
