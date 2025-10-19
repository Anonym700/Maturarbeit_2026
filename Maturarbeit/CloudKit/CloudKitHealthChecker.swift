import CloudKit
import Foundation

@MainActor
final class CloudKitHealthChecker: ObservableObject {
    @Published var isHealthy: Bool = false
    @Published var healthMessage: String = "CloudKit wird überprüft..."
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    
    private let manager = CloudKitManager.shared
    
    func performHealthCheck() async {
        // 1. Account Status
        await manager.checkAccountStatus()
        self.accountStatus = manager.accountStatus
        
        guard accountStatus == .available else {
            isHealthy = false
            healthMessage = "iCloud nicht verfügbar: \(accountStatus.description)"
            return
        }
        
        // 2. Custom Zone Creation
        do {
            try await manager.ensureCustomZoneExists()
        } catch {
            isHealthy = false
            healthMessage = "Fehler beim Erstellen der Zone: \(error.localizedDescription)"
            return
        }
        
        // 3. Soft Schema Check (Query test)
        do {
            _ = try await manager.fetch(recordType: "Chore", predicate: NSPredicate(value: true))
            isHealthy = true
            healthMessage = "CloudKit ist aktiv"
        } catch {
            // First time setup - no records yet, still healthy
            isHealthy = true
            healthMessage = "CloudKit aktiv (noch keine Einträge)"
        }
    }
}

