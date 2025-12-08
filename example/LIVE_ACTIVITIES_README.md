# Live Activities Integration with Nearby Connections

This example demonstrates how to integrate Live Activities (Android persistent notifications) with the Nearby Connections plugin.

## What's Included

### Android Native Files

1. **MainActivity.kt** (`android/app/src/main/kotlin/com/pkmnapps/nearby_connections_example/MainActivity.kt`)
   - Initializes the custom LiveActivityManager
   - Proper package name: `com.pkmnapps.nearby_connections_example`

2. **CustomLiveActivityManager.kt** (`android/app/src/main/kotlin/com/pkmnapps/nearby_connections_example/CustomLiveActivityManager.kt`)
   - Handles notification creation and updates
   - Displays connection status, device name, and data received
   - Shows connection time with a chronometer

3. **live_activity.xml** (`android/app/src/main/res/layout/live_activity.xml`)
   - Custom notification layout
   - Shows device name, connection status, data info, and connection time

4. **ic_notification.xml** (`android/app/src/main/res/drawable/ic_notification.xml`)
   - Notification icon

### Flutter Code

**lib/live_activity_integration.dart**
- `LiveActivityController` class for managing live activities
- Integration methods for:
  - Starting a connection activity
  - Updating connection status and data
  - Ending the activity
- Example widget demonstrating the integration

## Usage

### Using the LiveActivityController

```dart
import 'package:nearby_connections_example/live_activity_integration.dart';

final activityController = LiveActivityController();

// Start a live activity when connection is initiated
await activityController.startConnectionActivity(
  deviceName: 'Device Name',
  connectionStatus: 'Connecting...',
);

// Update the activity when receiving data
await activityController.updateConnectionActivity(
  deviceName: 'Device Name',
  connectionStatus: 'Connected',
  dataReceived: 'Hello from device!',
);

// End the activity when disconnected
await activityController.endConnectionActivity();
```

### Integration with Nearby Connections

The controller can be integrated into your existing Nearby Connections callbacks:

```dart
// In your connection initiated callback
void onConnectionInitiated(String endpointId, ConnectionInfo info) {
  activityController.startConnectionActivity(
    deviceName: info.endpointName,
    connectionStatus: 'Connecting...',
  );
}

// In your connection result callback
void onConnectionResult(String endpointId, Status status) {
  activityController.updateConnectionActivity(
    deviceName: connectedDevice,
    connectionStatus: status == Status.CONNECTED ? 'Connected' : 'Disconnected',
  );
}

// In your payload received callback
void onPayloadReceived(String endpointId, Payload payload) {
  if (payload.type == PayloadType.BYTES) {
    final data = String.fromCharCodes(payload.bytes!);
    activityController.updateConnectionActivity(
      deviceName: connectedDevice,
      connectionStatus: 'Connected',
      dataReceived: data,
    );
  }
}

// In your disconnection callback
void onDisconnected(String endpointId) {
  activityController.endConnectionActivity();
}
```

## Features

- ✅ Persistent notification showing connection status
- ✅ Real-time updates when receiving data
- ✅ Connection time tracking
- ✅ Clean integration with Nearby Connections
- ✅ Proper Android resource management

## Requirements

- Flutter SDK
- Android minSdkVersion: 24 or higher
- Dependencies:
  - `nearby_connections` (path dependency to parent)
  - `live_activities: ^2.4.3`

## Notes

- Live Activities on Android appear as persistent notifications
- The notification stays visible while the connection is active
- Automatically dismissed when the activity is ended
- The layout can be customized in `live_activity.xml`
