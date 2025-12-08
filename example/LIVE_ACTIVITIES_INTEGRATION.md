# Live Activities Integration for Nearby Connections

## Overview

This example app now includes iOS Live Activities integration that displays real-time connection status in a notification widget. The live activity shows:

- Current user name and status
- List of connected users (up to 3 displayed in the widget)
- Total number of connections
- Last update timestamp

## Features

### What's Tracked

The Live Activity widget displays:

1. **Current User Info**
   - Your device name (User: [random number])
   - Current connection status (Idle, Advertising, Discovering, Connected, etc.)

2. **Connected Users**
   - Names of connected endpoints
   - Their current activity status
   - Connection time

3. **Real-time Updates**
   - Automatically updates when users connect/disconnect
   - Updates when connection status changes
   - Updates when activity status is received from peers

## Implementation Details

### Key Components

#### 1. **ConnectionStatusModel** (`lib/models/connection_status_model.dart`)
A data model that represents the current state of connections:
- Current user name and status
- List of connected users with their info
- Timestamp of last update
- Total connection count

#### 2. **LiveActivities Integration** (in `main.dart`)
- Initialized in `_initializeLiveActivities()`
- Created when app starts via `_createLiveActivity()`
- Updated on connection events via `_updateLiveActivity()`
- Cleaned up on app dispose via `_endLiveActivity()`

### How It Works

1. **App Launch**
   - Live Activity is created with initial state (no connections)
   - Requests notification permission (required for Live Activities on iOS)

2. **Connection Events**
   - When a user connects, the live activity updates to show the new connection
   - When a user disconnects, the live activity removes them from the display
   - Activity status changes are reflected in real-time

3. **Activity Updates**
   - The `_updateActivityStatus()` method updates both the UI and Live Activity
   - Connection status changes trigger `_updateLiveActivity()`
   - Supports displaying up to 3 connected users in the widget

## iOS Configuration Requirements

To enable Live Activities on iOS, you need to:

### 1. Configure App Group

In your `ios/Runner.xcodeproj`:
- Add App Groups capability
- Create an app group ID (e.g., `group.nearbyconnections.example`)
- Ensure the app group ID matches what's used in `_initializeLiveActivities()`

### 2. Info.plist Configuration

Add to `ios/Runner/Info.plist`:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### 3. URL Scheme (Optional)

For URL scheme handling, add to `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>nearbyconnections</string>
        </array>
    </dict>
</array>
```

### 4. Create Live Activity Widget Extension

You'll need to create a Widget Extension in Xcode to display the Live Activity. This involves:
- Creating a new Widget Extension target
- Implementing ActivityConfiguration
- Designing the Live Activity UI using SwiftUI

## Usage

### Testing Live Activities

1. **Build and run on iOS device** (Live Activities don't work in simulator for full testing)
2. **Grant notification permission** when prompted
3. **Start Advertising or Discovery** to begin tracking connections
4. **Pull down notification shade** to see the Live Activity widget
5. **Connect with other devices** to see the widget update in real-time

### Debugging

- Check console logs for "Live Activity created/updated/ended" messages
- Ensure notification permissions are granted
- Verify app group ID is configured correctly
- Live Activities require iOS 16.1+

## Code Structure

### Main Updates in `main.dart`

```dart
// 1. Initialize LiveActivities plugin
final _liveActivitiesPlugin = LiveActivities();

// 2. Create activity on init
await _liveActivitiesPlugin.createActivity(
  activityId,
  _connectionStatusModel!.toMap(),
);

// 3. Update on connection changes
await _liveActivitiesPlugin.updateActivity(
  _liveActivityId!,
  _connectionStatusModel!.toMap(),
);

// 4. End activity on dispose
await _liveActivitiesPlugin.endActivity(_liveActivityId!);
```

## Data Flow

```
User Action (Connect/Disconnect)
    ↓
Update endpointMap
    ↓
Call _updateLiveActivity()
    ↓
Build ConnectedUser list from endpointMap
    ↓
Update ConnectionStatusModel
    ↓
Send to LiveActivities plugin
    ↓
iOS displays updated widget
```

## Platform Support

- **iOS 16.1+**: Full Live Activities support
- **Android**: Live Activities are iOS-only, but connection tracking still works
- The app gracefully handles platform differences and shows appropriate messages

## Limitations

1. **iOS Widget Constraints**
   - Widget can display up to 3 connected users (additional users shown in count)
   - Limited space for activity descriptions
   - Widget updates are throttled by iOS

2. **Battery Considerations**
   - Live Activities are designed for temporary states
   - iOS may end activities that run too long
   - Consider battery impact of frequent updates

## Future Enhancements

Potential improvements:
- [ ] Custom SwiftUI widget design
- [ ] Interactive buttons in Live Activity (iOS 17+)
- [ ] Activity history in widget
- [ ] Rich notifications with connection details
- [ ] Customizable widget appearance

## References

- [Flutter Live Activities Package](https://pub.dev/packages/live_activities)
- [Apple Live Activities Documentation](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [Nearby Connections Plugin](https://pub.dev/packages/nearby_connections)
