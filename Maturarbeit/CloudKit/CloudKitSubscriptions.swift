import CloudKit
import Foundation

@MainActor
final class CloudKitSubscriptions {
    private let manager = CloudKitManager.shared
    
    /// Setup query subscriptions for Chore, FamilyMember, and Share changes
    func setupSubscriptions() async throws {
        // Setup in private database
        try await setupSubscription(for: "Chore", in: manager.privateDB)
        try await setupSubscription(for: "FamilyMember", in: manager.privateDB)
        try await setupSubscription(for: "cloudkit.share", in: manager.privateDB)
        
        // Also setup in shared database for participants
        try await setupSubscription(for: "Chore", in: manager.sharedDB, suffix: "Shared")
        try await setupSubscription(for: "FamilyMember", in: manager.sharedDB, suffix: "Shared")
        try await setupSubscription(for: "cloudkit.share", in: manager.sharedDB, suffix: "Shared")
        
        print("✅ CloudKit subscriptions configured (Private + Shared)")
    }
    
    private func setupSubscription(for recordType: String, in database: CKDatabase, suffix: String = "") async throws {
        let subscriptionID = "\(recordType)Subscription\(suffix)"
        let predicate = NSPredicate(value: true)
        
        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        do {
            _ = try await database.save(subscription)
            print("✅ Created/updated subscription: \(subscriptionID)")
        } catch let error as CKError {
            // Subscription bereits vorhanden oder Server nimmt Update statt Create
            if error.code == .serverRejectedRequest || error.code == .unknownItem {
                print("ℹ️ Subscription '\(subscriptionID)' already exists/updated")
            } else {
                throw error
            }
        }
    }
    
    /// Handle remote notification (call from AppDelegate/SceneDelegate)
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            return
        }
        
        if let queryNotification = notification as? CKQueryNotification {
            print("📬 CloudKit change detected: \(queryNotification.recordID?.recordName ?? "unknown")")
            // Trigger UI refresh via NotificationCenter or Publisher
            NotificationCenter.default.post(name: .cloudKitDataChanged, object: nil)
        }
    }
}

extension Notification.Name {
    static let cloudKitDataChanged = Notification.Name("cloudKitDataChanged")
}

