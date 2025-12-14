//
//  AppDelegate.swift
//  VIBRA
//
//  AppDelegate for notification permission and lifecycle handling
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        print("🚀 AppDelegate: Application launched")
        
        // Set NotificationManager as the delegate for UNUserNotificationCenter
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        // Request notification permissions
        NotificationManager.shared.requestNotificationPermissions { granted in
            if granted {
                print("✅ AppDelegate: Notification permissions granted")
            } else {
                print("⚠️ AppDelegate: Notification permissions denied")
            }
        }
        
        // Check if user is already logged in and start polling
        if let token = try? KeychainManager.shared.getJWT() {
            print("🔑 AppDelegate: Found existing JWT, starting polling")
            NotificationManager.shared.startPolling(withJWT: token)
        }
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("👋 AppDelegate: Application terminating")
        NotificationManager.shared.stopPolling()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("📱 AppDelegate: Entered background")
        // Polling will continue in background for a limited time
        // iOS allows ~3 minutes of background execution
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("📱 AppDelegate: Entering foreground")
        // Update badge count when returning to foreground
        NotificationManager.shared.updateBadgeCount()
    }
}
