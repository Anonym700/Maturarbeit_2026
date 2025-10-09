import Foundation

@MainActor
final class LocalToCloudKitMigration {
    private let inMemoryStore = InMemoryStore()
    private let cloudKitStore = CloudKitStore()
    
    /// Perform one-time migration from InMemory to CloudKit
    func migrateIfNeeded() async {
        let migrationKey = "hasPerformedCloudKitMigration_v1"
        
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            print("ℹ️ Migration already performed, skipping...")
            return
        }
        
        print("🔄 Starting local → CloudKit migration...")
        
        let localChores = await inMemoryStore.loadChores()
        
        for chore in localChores {
            await cloudKitStore.saveChore(chore)
        }
        
        UserDefaults.standard.set(true, forKey: migrationKey)
        print("✅ Migration complete: \(localChores.count) chores migrated")
    }
}

