//
//  LocalNotificationManager.swift
//  VIBRA
//
//  Local notification manager for iOS notification center
//

import Foundation
import UserNotifications

final class LocalNotificationManager: NSObject {
    static let shared = LocalNotificationManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Request Permission
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error)")
            }
            print(granted ? "✅ Notification permission granted" : "⚠️ Notification permission denied")
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // MARK: - Check Permission Status
    
    func checkPermissionStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - Show Local Notification
    
    func showNotification(
        title: String,
        body: String,
        identifier: String = UUID().uuidString,
        badge: Int? = nil,
        sound: UNNotificationSound = .default,
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.userInfo = userInfo
        
        if let badge = badge {
            content.badge = NSNumber(value: badge)
        }
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                print("✅ Local notification scheduled: \(title)")
            }
        }
    }
    
    // MARK: - Update Badge Count
    
    func updateBadge(count: Int) {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
                if let error = error {
                    print("❌ Failed to update badge: \(error)")
                } else {
                    print("✅ Badge updated: \(count)")
                }
            }
        }
    }
    
    // MARK: - Clear Badge
    
    func clearBadge() {
        updateBadge(count: 0)
    }
    
    // MARK: - Remove Delivered Notifications
    
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func removeAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension LocalNotificationManager: UNUserNotificationCenterDelegate {
    
    // Called when notification is received while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📬 Notification received in foreground: \(notification.request.content.title)")
        
        // Show banner, play sound, and update badge even when app is open
        completionHandler([.banner, .sound, .badge])
    }
    
    // Called when user taps on notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("👆 User tapped notification with userInfo: \(userInfo)")
        
        // Handle notification tap based on type
        if let type = userInfo["type"] as? String {
            NotificationCenter.default.post(
                name: NSNotification.Name("HandleNotificationTap"),
                object: nil,
                userInfo: userInfo
            )
        }
        
        completionHandler()
    }
}
