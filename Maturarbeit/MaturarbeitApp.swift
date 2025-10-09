//
//  MaturarbeitApp.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import SwiftUI
import CloudKit

@main
struct MaturarbeitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var healthChecker = CloudKitHealthChecker()
    
    init() {
        // Perform health check on launch
        Task { @MainActor in
            await healthChecker.performHealthCheck()
            
            if healthChecker.isHealthy {
                // Perform migration if needed
                await LocalToCloudKitMigration().migrateIfNeeded()
                
                // Setup subscriptions
                try? await CloudKitSubscriptions().setupSubscriptions()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(healthChecker)
        }
    }
}
