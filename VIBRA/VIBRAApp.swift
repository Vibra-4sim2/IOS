//
//  VIBRAApp.swift
//  VIBRA
//

import SwiftUI
import CoreData

@main
struct VIBRAApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var ratingPromptViewModel = RatingPromptViewModel()

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(ratingPromptViewModel)
        }
    }
}
