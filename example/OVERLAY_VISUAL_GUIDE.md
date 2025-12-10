# Screen Overlay Visual Guide

## Overlay Appearance

The overlay appears as a semi-transparent floating widget on your screen:

### Idle State (No Connections)
```
╔═══════════════════════════════╗
║ 🕐  User1234                  ║
║     Idle                      ║
║     ● 0 connected             ║
╚═══════════════════════════════╝
```

### Active State (1 Connection)
```
╔═══════════════════════════════╗
║ ✏️  User1234                  ║
║     Typing Message            ║
║     ● 1 connected             ║
║  ┌───────────────────────┐    ║
║  │ • User5678            │    ║
║  │   Browsing Photos     │    ║
║  └───────────────────────┘    ║
╚═══════════════════════════════╝
```

### Multiple Connections
```
╔═══════════════════════════════╗
║ 🧭  User1234                  ║
║     Browsing Home             ║
║     ● 3 connected             ║
║  ┌───────────────────────┐    ║
║  │ • User5678            │    ║
║  │   Writing Notes       │    ║
║  └───────────────────────┘    ║
╚═══════════════════════════════╝
```

## Color Scheme

- **Background**: Semi-transparent black (#E6000000)
- **Border**: Light transparent white (#40FFFFFF)
- **Primary Text**: White (#FFFFFF)
- **Secondary Text**: Light gray (#E0E0E0)
- **Connection Indicator**: Green (#4CAF50)
- **Activity Icon**: Blue (#2196F3)

## Size & Position

- **Initial Position**: Top-right corner, 16px from edge, 100px from top
- **Width**: Wraps content (typically 200-250px)
- **Height**: Adjusts based on content
- **Draggable**: Yes - touch and drag anywhere on the overlay

## Interaction

1. **Tap and Hold**: Starts dragging
2. **Move**: Reposition the overlay
3. **Release**: Overlay stays in new position
4. **No Click-through**: Overlay captures touches on its bounds

## Activity Icon Legend

Icon | Activity Types
-----|---------------
🕐   | Idle (default)
✏️   | Typing, Typing Message, Writing Notes
🧭   | Browsing, Browsing Home, Browsing Photos
📧   | Viewing Messages, Reading Messages
📝   | Editing Document, Editing Profile, Taking Notes
📋   | Filling Form
👁️   | Viewing Page
❓   | Unknown/Other activities
