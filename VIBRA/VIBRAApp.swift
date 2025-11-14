//
//  VIBRAApp.swift
//  VIBRA
//
//  Created by mac book pro on 11/6/25.
//

import SwiftUI
import CoreData

@main
struct VIBRAApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            SplashScreenView() // ✅ Démarre toujours par le Splash
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
