//
//  VIBRAApp.swift
//  VIBRA
//

import SwiftUI
import CoreData
import UserNotifications

@main
struct VIBRAApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var ratingPromptViewModel = RatingPromptViewModel()
    
    init() {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = LocalNotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(ratingPromptViewModel)
        }
    }
}
