import UIKit
import CloudKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Remote Notifications registrieren (keine User-Permission nötig für stille Pushes)
        UIApplication.shared.registerForRemoteNotifications()
        print("📱 Registering for remote notifications...")
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ Registered for remote notifications. Token: \(token)")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📬 Received remote notification: \(userInfo)")
        
        Task {
            await CloudKitSubscriptions().handleRemoteNotification(userInfo)
            completionHandler(.newData)
        }
    }
}

// MARK: - CloudKit Share Acceptance (invoked when tapping iCloud share links)
extension AppDelegate {
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        Task { @MainActor in
            do {
                try await CloudKitManager.shared.acceptShare(metadata: metadata)
                print("✅ CloudKit share accepted via URL")
            } catch {
                print("❌ Failed to accept CloudKit share: \(error)")
            }
        }
    }
}

