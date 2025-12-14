# 🚀 Quick Start Guide - Testing Notification Polling

## Prerequisites
- Xcode installed
- iOS Simulator or physical device
- Backend running at `https://dam-4sim2.onrender.com`

## Step 1: Build and Run

1. Open the project in Xcode:
   ```bash
   cd "/Users/mohamedmami/Desktop/Ios amine/IOS"
   open VIBRA.xcodeproj
   ```

2. Select target device (Simulator or your iPhone)

3. Build and run (⌘R)

## Step 2: First Launch

You should see these console logs:

```
🚀 AppDelegate: Application launched
✅ AppDelegate: Notification permissions granted
```

A notification permission dialog will appear - **tap "Allow"**

## Step 3: Login

1. Enter valid credentials
2. Tap login button

Watch console for:

```
✅ Token reçu : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
🔔 NotificationManager: Starting notification polling every 30.0s
📬 NotificationManager: Received 0 unread notifications
🔔 NotificationManager: Badge count updated to 0
```

## Step 4: Create Test Notification

### Option A: Using Backend Directly

Send a POST request to create a publication (which triggers a notification):

```bash
curl -X POST https://dam-4sim2.onrender.com/publication \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "author": "YOUR_USER_ID",
    "content": "Test publication for notifications",
    "tags": "test"
  }'
```

### Option B: Using the App

1. Go to Feed tab
2. Create a new publication
3. This will trigger notifications for your followers (and yourself in test mode)

## Step 5: Wait for Notification

Within **30 seconds**, you should see:

### In Console:
```
📬 NotificationManager: Received 1 unread notifications
✅ NotificationManager: Displayed notification: John Doe a publié
✅ NotificationManager: Marked as read: 675d1234abcd5678efgh9012
🔔 NotificationManager: Badge count updated to 1
```

### On Device:
- Local notification banner appears
- Sound plays
- Badge count shows on app icon

## Step 6: Test Notification Tap

1. **Background Test:**
   - Put app in background (swipe up/home button)
   - Tap the notification
   - App opens and navigates to publication detail

   Console:
   ```
   📬 NotificationManager: Notification tapped
   🧭 NotificationManager: Routing to new_publication
      → Navigate to publication: 675d1234...
   ```

2. **Foreground Test:**
   - Keep app open
   - Create another notification
   - Notification appears as banner even in foreground
   - Tap banner to navigate

## Step 7: Test Badge Count

1. Create multiple notifications (2-3)
2. Check app icon badge updates
3. Open app
4. Badge should reflect unread count from backend

## Step 8: Test Logout

1. Go to Profile tab
2. Tap logout button
3. Confirm logout

Console:
```
🔔 NotificationManager: Stopped polling
```

4. Badge count resets to 0
5. No more polling happens

## Step 9: Test Auto-Resume

1. Force quit the app (swipe up from multitasking)
2. Reopen the app
3. If JWT exists, polling starts automatically

Console:
```
🔑 AppDelegate: Found existing JWT, starting polling
🔔 NotificationManager: Starting notification polling every 30.0s
```

## Debugging Tips

### Enable Verbose Logging

All important events are already logged with emojis:
- 🚀 App lifecycle
- 🔔 Notification system
- 📬 Polling and notifications
- ✅ Success
- ❌ Errors
- ⚠️ Warnings
- 🧭 Navigation

### Check Notification Permissions

If notifications don't appear:

1. iOS Simulator: Check notification center (swipe down from top)
2. Physical device: Settings → VIBRA → Notifications → Ensure "Allow Notifications" is ON

### Test Network Connection

```bash
# Test backend is reachable
curl https://dam-4sim2.onrender.com/notifications/unread-count \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

Expected response:
```json
{"count": 0}
```

### Clear Notification History

If you see duplicate notifications or want to reset:

Add this temporary button in your UI:

```swift
Button("Clear Notification History") {
    NotificationManager.shared.clearDisplayedNotifications()
}
```

### Monitor Polling Activity

Watch console logs - you should see a poll attempt every 30 seconds:

```
📬 NotificationManager: Received X unread notifications
```

If polling stops, check:
- JWT token is valid (not expired)
- Network connection is active
- App hasn't been force-terminated by iOS

## Common Issues

### Issue: "⚠️ NotificationManager: No JWT token available"
**Solution:** Login again to get a fresh JWT token

### Issue: Notifications appear but don't navigate
**Solution:** Check that the notification `type` is handled in `NotificationManager.handleNotificationTap()`

### Issue: Polling only works for 3 minutes in background
**Expected behavior:** iOS limits background execution. Polling resumes when app returns to foreground.

### Issue: Badge count is wrong
**Solution:** Call `NotificationManager.shared.updateBadgeCount()` manually

## Performance Testing

### Test Polling Frequency

1. Set polling interval to 10 seconds (for testing):
   ```swift
   // In NotificationManager.swift
   private let pollingInterval: TimeInterval = 10
   ```

2. Create notifications and verify they appear within 10 seconds

3. Restore to 30 seconds for production

### Test High Volume

1. Create 10+ notifications quickly
2. Verify all are displayed
3. Check for duplicate prevention
4. Verify all are marked as read

## Success Criteria

✅ Notification permissions granted on first launch

✅ Polling starts automatically after login

✅ New notifications appear within 30 seconds

✅ Tapping notification navigates to correct screen

✅ Badge count updates correctly

✅ Notifications marked as read automatically

✅ Polling stops on logout

✅ Badge resets to 0 on logout

✅ No duplicate notifications

✅ No crashes or memory leaks

## Next Steps

After successful testing:

1. **Add UI for notification list** (optional)
   - Show unread notifications in-app
   - Allow manual mark as read
   - Add notification preferences

2. **Add notification categories** (optional)
   - Different icons per type
   - Interactive buttons (Mark as read, View)

3. **Optimize polling interval**
   - 30s for active users
   - 60s for battery saving

4. **Add analytics**
   - Track notification delivery rate
   - Monitor tap-through rate
   - Measure average latency

5. **Consider APNs migration** (if needed)
   - For real-time delivery (<5s latency)
   - For silent background updates
   - For notification actions/categories

## Support Contacts

- **Backend API Issues:** Check backend logs and `/notifications` endpoint
- **iOS Issues:** Review console logs and this documentation
- **Notification Permissions:** Settings → VIBRA → Notifications

---

**Happy Testing! 🎉**

If everything works as expected, your notification system is ready for production use.
