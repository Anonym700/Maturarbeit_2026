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
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(healthChecker)
                .task {
                    // Perform health check on launch
                    await healthChecker.performHealthCheck()
                    
                    if healthChecker.isHealthy {
                        // Perform migration if needed
                        await LocalToCloudKitMigration().migrateIfNeeded()
                        
                        // Setup subscriptions
                        try? await CloudKitSubscriptions().setupSubscriptions()
                    }
                }
                .onOpenURL { url in
                    // Handle CloudKit share URLs
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        Task { @MainActor in
            // Check if this is a CloudKit share URL
            let container = CKContainer(identifier: "iCloud.com.christosalexisfantino.MaturarbeitApp")
            
            do {
                // Use continuation to convert callback to async/await
                let metadata: CKShare.Metadata = try await withCheckedThrowingContinuation { continuation in
                    container.fetchShareMetadata(with: url) { metadata, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let metadata = metadata {
                            continuation.resume(returning: metadata)
                        } else {
                            continuation.resume(throwing: CKError(.unknownItem))
                        }
                    }
                }
                
                // Accept the share
                try await CloudKitManager.shared.acceptShare(metadata: metadata)
                
                print("✅ Successfully joined family share!")
            } catch {
                print("❌ Failed to accept share: \(error)")
            }
        }
    }
}
