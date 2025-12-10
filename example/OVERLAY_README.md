# Screen Overlay Feature for Android

This feature adds a floating overlay widget that displays live connection updates directly on the device screen, appearing above all other apps.

## Features

- **Customizable Design**: Small icon on the left, text information on the right
- **Draggable Widget**: Users can move the overlay around the screen
- **Real-time Updates**: Shows your current activity and connected users
- **Activity Icons**: Dynamic icons based on the type of activity
- **Connection Badge**: Visual indicator showing number of connected devices
- **First User Display**: Shows the first connected user's name and activity

## Design

The overlay follows this layout:
```
┌─────────────────────────────────┐
│ 🔵  Your Name                   │
│     Your Activity               │
│     ● 3 connected               │
│  ┌──────────────────────────┐   │
│  │ • Friend Name            │   │
│  │   Their Activity         │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
```

## Usage

1. **Enable Screen Overlay**: Tap the "Enable Screen Overlay" button in the main app
2. **Grant Permission**: On first use, you'll be asked to grant "Display over other apps" permission
3. **Position the Overlay**: Drag the overlay to your preferred location on screen
4. **Automatic Updates**: The overlay updates automatically when:
   - Your activity changes
   - Devices connect/disconnect
   - Connected users change their activity

## Permissions Required

The overlay requires the `SYSTEM_ALERT_WINDOW` permission, which allows the app to draw over other applications. This permission must be granted by the user in Android settings.

## Implementation Details

### Android Components

1. **OverlayService.kt**: Service that manages the floating overlay window
   - Creates and manages the WindowManager overlay
   - Handles dragging functionality
   - Updates overlay content

2. **overlay_widget.xml**: Layout for the overlay UI
   - Icon-text horizontal layout
   - Semi-transparent background
   - Rounded corners for modern look

3. **MainActivity.kt**: Bridge between Flutter and native Android
   - Permission checks
   - Service management
   - Data passing to overlay

### Flutter Integration

The overlay is controlled through a MethodChannel:
- `checkOverlayPermission`: Verify if permission is granted
- `requestOverlayPermission`: Request permission from user
- `showOverlay`: Display the overlay with data
- `updateOverlay`: Update overlay content
- `hideOverlay`: Remove the overlay from screen

## Activity Icons

The overlay displays different icons based on activity type:
- 🕐 Idle: Recent history icon
- ✏️ Typing/Writing: Edit icon
- 🧭 Browsing: Compass icon
- 📧 Viewing Messages: Message icon
- 📝 Editing Document: Manage icon
- 📋 Filling Form: Agenda icon
- 👁️ Viewing Page: Info icon
- ❓ Unknown: Help icon

## Customization

To customize the overlay appearance, modify these files:

- **Layout**: `android/app/src/main/res/layout/overlay_widget.xml`
- **Background**: `android/app/src/main/res/drawable/overlay_background.xml`
- **Colors**: Update color values in the XML files
- **Size**: Adjust dimensions in `overlay_widget.xml`
- **Position**: Change initial position in `OverlayService.kt` (params.x, params.y)

## Technical Notes

- The overlay uses `TYPE_APPLICATION_OVERLAY` for Android O+ and `TYPE_PHONE` for older versions
- Window flags ensure the overlay doesn't interfere with touch events outside its bounds
- The overlay persists across app switching but is destroyed when the service stops
- Updates are efficient and only redraw changed content

## Privacy & Battery

- The overlay only displays information you explicitly share
- Minimal battery impact - updates only when connection status changes
- No data is collected or transmitted beyond the peer-to-peer connection
- Overlay stops when you disable it or close the app

## Troubleshooting

**Overlay doesn't appear:**
- Check if "Display over other apps" permission is granted
- Try disabling and re-enabling the overlay
- Restart the app

**Overlay appears in wrong position:**
- Drag it to your preferred location
- The position persists during the session

**Overlay not updating:**
- Ensure you're connected to other devices
- Check that live activity is also enabled
- Look for error messages in the console
