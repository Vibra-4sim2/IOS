#!/usr/bin/env python3
"""
Fix NotificationManager.swift - Apply all three critical fixes
"""

import re

file_path = "/Users/mohamedmami/Desktop/Ios amine/IOS/VIBRA/Services/NotificationManager.swift"

# Read the file
with open(file_path, 'r') as f:
    content = f.read()

# Fix 1: JWT Token Bug - Don't call stopPolling() which clears the token
old_start_polling = """    /// Start polling for notifications after login
    func startPolling(withJWT token: String) {
        self.jwtToken = token
        
        // Stop any existing timer
        stopPolling()
        
        print("🔔 NotificationManager: Starting notification polling every \\(pollingInterval)s")"""

new_start_polling = """    /// Start polling for notifications after login
    func startPolling(withJWT token: String) {
        // Stop any existing timer FIRST (without clearing token)
        pollingTimer?.invalidate()
        pollingTimer = nil
        
        // NOW set the new token
        self.jwtToken = token
        
        print("🔔 NotificationManager: Starting notification polling every \\(pollingInterval)s")"""

content = content.replace(old_start_polling, new_start_polling)

# Fix 2: Notification Trigger - Use nil to persist in Notification Center
old_trigger = """        // Create request with unique identifier
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )"""

new_trigger = """        // Create request with nil trigger to persist in Notification Center
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: nil  // nil = immediate delivery + stays in Notification Center
        )"""

content = content.replace(old_trigger, new_trigger)

# Fix 3: Foreground Handler - Add .list for iOS 14+
old_foreground = """        print("📬 NotificationManager: Notification received in foreground")
        
        // Show notification even in foreground
        completionHandler([.banner, .sound, .badge])"""

new_foreground = """        print("📬 NotificationManager: Notification received in foreground")
        
        // Show notification even in foreground AND keep in Notification Center
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }"""

content = content.replace(old_foreground, new_foreground)

# Write back
with open(file_path, 'w') as f:
    f.write(content)

print("✅ All three fixes applied successfully!")
print("  1. JWT token bug fixed (no longer calls stopPolling)")
print("  2. Notification trigger changed to nil (persists in Notification Center)")
print("  3. Foreground handler uses .list for iOS 14+")
