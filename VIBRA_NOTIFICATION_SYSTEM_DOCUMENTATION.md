# 🔔 VIBRA Notification Polling System

## Overview
This notification system uses **backend polling + local notifications** instead of Firebase Cloud Messaging (FCM) or Apple Push Notification Service (APNs). This approach:

- ✅ Works on **iOS Simulator** and real devices
- ✅ **100% FREE** (no APNs certificate/key required)
- ✅ No Firebase push setup needed
- ✅ Simple to test and debug
- ✅ Reliable for moderate notification volumes

## Architecture

### Components

1. **NotificationItem.swift** - Data models matching backend API
2. **NotificationManager.swift** - Singleton service handling polling and local notifications
3. **AppDelegate.swift** - App lifecycle and notification permissions
4. **VIBRAApp.swift** - SwiftUI app with integrated AppDelegate
5. **LoginViewModel.swift** - Starts polling after login
6. **TabBarView.swift** - Stops polling on logout

### Flow Diagram

```
┌─────────────┐
│ User Login  │
└──────┬──────┘
       │
       v
┌──────────────────────────┐
│ Save JWT to Keychain     │
└──────────┬───────────────┘
           │
           v
┌──────────────────────────┐
│ Start Polling (30s)      │
└──────────┬───────────────┘
           │
           v
┌──────────────────────────────────────┐
│ Every 30s:                           │
│  GET /notifications?unreadOnly=true  │
└──────────┬───────────────────────────┘
           │
           v
┌──────────────────────────┐
│ New notifications?       │
└──────────┬───────────────┘
           │
           v YES
┌──────────────────────────┐
│ Show Local Notification  │
│ PATCH /notifications/:id/read │
└──────────┬───────────────┘
           │
           v
┌──────────────────────────┐
│ User Taps Notification   │
└──────────┬───────────────┘
           │
           v
┌──────────────────────────┐
│ Deep Link to Screen      │
│ (Publication/Chat/Ride)  │
└──────────────────────────┘
```

## Backend API Contract

### 1. Login (Get JWT)
```http
POST https://dam-4sim2.onrender.com/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 2. Poll Notifications (Called Every 30s)
```http
GET https://dam-4sim2.onrender.com/notifications?unreadOnly=true&limit=10
Authorization: Bearer <JWT_TOKEN>
```

**Response:**
```json
[
  {
    "id": "675d1234abcd5678efgh9012",
    "title": "John Doe a publié",
    "body": "Nouvelle publication disponible",
    "type": "new_publication",
    "data": {
      "type": "new_publication",
      "publicationId": "675d...",
      "authorId": "691...",
      "authorName": "John Doe"
    },
    "isRead": false,
    "createdAt": "2025-12-14T14:00:00.000Z",
    "readAt": null
  }
]
```

### 3. Mark as Read
```http
PATCH https://dam-4sim2.onrender.com/notifications/:id/read
Authorization: Bearer <JWT_TOKEN>
```

**Response:**
```json
{
  "success": true,
  "message": "Notification marquée comme lue"
}
```

### 4. Get Unread Count (For Badge)
```http
GET https://dam-4sim2.onrender.com/notifications/unread-count
Authorization: Bearer <JWT_TOKEN>
```

**Response:**
```json
{
  "count": 5
}
```

## Notification Types & Routing

| Type | Required Data | Navigates To |
|------|---------------|--------------|
| `new_publication` | `publicationId` | Publication detail screen |
| `chat_message` | `sortieId`, `chatId` | Chat screen |
| `ride_update` | `rideId` | Ride detail screen |
| `new_ride` | `rideId` | Ride detail screen |

### Adding New Notification Types

To add a new notification type:

1. **Backend**: Ensure it sends the correct `type` and required fields in `data`
2. **iOS**: Update `NotificationManager.handleNotificationTap()`:

```swift
case "your_new_type":
    if let entityId = userInfo["entityId"] as? String {
        NotificationCenter.default.post(
            name: NotificationManager.navigateToYourScreen,
            object: nil,
            userInfo: ["entityId": entityId]
        )
    }
```

3. **Add routing in your SwiftUI views**:

```swift
.onReceive(NotificationCenter.default.publisher(for: NotificationManager.navigateToYourScreen)) { notification in
    if let userInfo = notification.userInfo,
       let entityId = userInfo["entityId"] as? String {
        // Navigate to your screen
    }
}
```

## Configuration

### Polling Interval
Default: **30 seconds**

To change, edit `NotificationManager.swift`:
```swift
private let pollingInterval: TimeInterval = 30 // Change to 60 for 1 minute
```

### Backend URL
Set in `Constants.swift`:
```swift
static let baseURL = "https://dam-4sim2.onrender.com"
```

## Testing Checklist

### Setup Testing
- [ ] Clean install on device/simulator
- [ ] Login with valid credentials
- [ ] Check console logs for "✅ Notification permissions granted"
- [ ] Check console logs for "🔔 Starting notification polling"

### Notification Delivery Testing
- [ ] Create a test notification in backend (e.g., new publication)
- [ ] Wait up to 30 seconds
- [ ] Check console: "📬 Received X unread notifications"
- [ ] Local notification appears on device
- [ ] Check console: "✅ Displayed notification: [title]"
- [ ] Notification is marked as read automatically

### Interaction Testing
- [ ] Tap notification while app is in background
- [ ] App opens and navigates to correct screen
- [ ] Tap notification while app is in foreground
- [ ] Navigation happens without reopening app
- [ ] Badge count updates correctly

### Logout Testing
- [ ] Logout from app
- [ ] Check console: "🔔 Stopped polling"
- [ ] Badge count resets to 0
- [ ] No more polling happens (check console logs)

### Edge Cases
- [ ] App killed and reopened (JWT should auto-start polling)
- [ ] Network error during polling (gracefully handled)
- [ ] Invalid JWT (polling stops, no crashes)
- [ ] Duplicate notifications (not shown twice)

## Console Log Reference

### Successful Flow
```
🚀 AppDelegate: Application launched
✅ AppDelegate: Notification permissions granted
🔑 AppDelegate: Found existing JWT, starting polling
🔔 NotificationManager: Starting notification polling every 30.0s
📬 NotificationManager: Received 2 unread notifications
✅ NotificationManager: Displayed notification: John Doe a publié
✅ NotificationManager: Marked as read: 675d1234...
🔔 NotificationManager: Badge count updated to 2
📬 NotificationManager: Notification tapped
🧭 NotificationManager: Routing to new_publication
   → Navigate to publication: 675d1234...
```

### Logout Flow
```
🔔 NotificationManager: Stopped polling
👋 AppDelegate: Application terminating
```

## Troubleshooting

### Problem: Notifications not appearing
**Solutions:**
1. Check notification permissions: Settings → VIBRA → Notifications
2. Verify JWT token is valid: Check console for "⚠️ No JWT token available"
3. Check backend is returning notifications: Test `/notifications` endpoint manually
4. Ensure polling is running: Look for "🔔 Starting notification polling" in console

### Problem: Badge count not updating
**Solutions:**
1. Verify `/notifications/unread-count` endpoint works
2. Check app has permission to modify badge: Settings → VIBRA → Badges
3. Call `NotificationManager.shared.updateBadgeCount()` manually

### Problem: Duplicate notifications
**Solutions:**
1. Check `displayedNotificationIds` in UserDefaults
2. Clear history: `NotificationManager.shared.clearDisplayedNotifications()`

### Problem: Navigation not working
**Solutions:**
1. Verify notification `type` matches case in `handleNotificationTap()`
2. Check required data fields are present (e.g., `publicationId`, `chatId`)
3. Ensure target view is observing the correct NotificationCenter name

### Problem: Polling stops unexpectedly
**Solutions:**
1. Check JWT hasn't expired (401 error in logs)
2. Verify network connectivity
3. Check app hasn't been force-quit by iOS due to excessive background activity

## Performance Considerations

### Battery Impact
- Polling every 30s has minimal battery impact
- iOS manages background execution time automatically
- Polling continues for ~3 minutes after app enters background
- For lower battery usage, increase polling interval to 60s

### Network Usage
- Each poll request is ~1-2 KB
- At 30s interval: ~2 requests/minute = ~120 requests/hour
- Daily network usage: ~5-10 MB (negligible)

### Notification Latency
- Maximum latency: 30 seconds (polling interval)
- Average latency: 15 seconds
- For real-time notifications (<5s), consider implementing APNs/FCM

## Migration to APNs/FCM (Future)

If you later need real-time push notifications:

1. **Keep** the polling system as fallback
2. **Add** APNs registration in AppDelegate
3. **Integrate** Firebase Messaging SDK
4. **Register** device tokens with backend
5. **Backend** sends via both FCM and polling initially
6. **Gradually** phase out polling for active users

## Files Summary

| File | Purpose | Lines |
|------|---------|-------|
| `Models/NotificationItem.swift` | Data models | ~100 |
| `Services/NotificationManager.swift` | Polling & local notifications | ~400 |
| `AppDelegate.swift` | App lifecycle & permissions | ~50 |
| `VIBRAApp.swift` | SwiftUI app entry point | ~25 |
| `ViewModels/LoginViewModel.swift` | Start polling on login | ~60 |
| `Views/TabBarView.swift` | Stop polling on logout | ~250+ |

## Support

For questions or issues:
1. Check console logs for error messages
2. Verify backend API endpoints are accessible
3. Test notification permissions in iOS Settings
4. Review this documentation thoroughly

## License

This notification system is part of the VIBRA iOS app.

---

**Last Updated:** December 14, 2025
**Version:** 1.0.0
**Author:** VIBRA Development Team
