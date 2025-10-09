import CloudKit
import Foundation

/*
 🔧 MANUELLE XCODE-KONFIGURATION ERFORDERLICH:
 
 1. Öffne Maturarbeit.xcodeproj in Xcode
 2. Wähle Target "Maturarbeit" → "Signing & Capabilities"
 3. Aktiviere folgende Capabilities:
    
    ✅ iCloud
       - CloudKit aktivieren
       - Container: iCloud.com.christosalexisfantino.MaturarbeitApp
    
    ✅ Push Notifications
    
    ✅ Background Modes
       - Remote notifications aktivieren (optional für Background-Sync)
 
 4. Stelle sicher, dass ein gültiges Signing Team ausgewählt ist
 5. Teste auf einem echten Gerät mit der gleichen Apple ID (Simulator iCloud ist instabil!)
 */

@MainActor
final class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    // MARK: - CloudKit Properties
    let container: CKContainer
    let privateDB: CKDatabase
    let customZone: CKRecordZone
    
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isHealthy: Bool = false
    
    // MARK: - Configuration
    private let containerID = "iCloud.com.christosalexisfantino.MaturarbeitApp"
    private let customZoneName = "MainZone"
    
    private init() {
        self.container = CKContainer(identifier: containerID)
        self.privateDB = container.privateCloudDatabase
        self.customZone = CKRecordZone(zoneName: customZoneName)
        
        print("☁️ CloudKit initialized: \(containerID)")
    }
    
    // MARK: - Health Check
    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            self.accountStatus = status
            print("☁️ Account Status: \(status.description)")
        } catch {
            print("❌ Failed to check account status: \(error)")
            self.accountStatus = .couldNotDetermine
        }
    }
    
    // MARK: - Zone Management
    func ensureCustomZoneExists() async throws {
        do {
            let (saveResults, _) = try await privateDB.modifyRecordZones(
                saving: [customZone],
                deleting: []
            )
            
            if case .success = saveResults[customZone.zoneID] {
                print("✅ Custom zone '\(customZoneName)' created/verified")
            } else {
                print("✅ Custom zone '\(customZoneName)' already exists or up to date")
            }
        } catch {
            // Falls Zone bereits existiert oder Race Condition vorliegt
            if let ckError = error as? CKError, ckError.code == .serverRecordChanged {
                print("✅ Custom zone '\(customZoneName)' already exists (serverRecordChanged)")
                return
            }
            print("❌ Failed to create custom zone: \(error)")
            throw error
        }
    }
    
    // MARK: - CRUD Operations with Retry Logic
    
    /// Save single record with conflict resolution
    func save(_ record: CKRecord) async throws -> CKRecord {
        let policy: CKModifyRecordsOperation.RecordSavePolicy = .changedKeys
        
        return try await withRetry(maxAttempts: 3) {
            let (results, _) = try await self.privateDB.modifyRecords(
                saving: [record],
                deleting: [],
                savePolicy: policy
            )
            
            guard let savedRecord = results.first?.1.get() else {
                throw CKError(.unknownItem)
            }
            return savedRecord
        }
    }
    
    /// Fetch records by query (always in custom zone)
    func fetch(
        recordType: String,
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor] = []
    ) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors
        
        return try await withRetry(maxAttempts: 3) {
            let (matches, _) = try await self.privateDB.records(
                matching: query,
                inZoneWith: self.customZone.zoneID
            )
            return matches.compactMap { try? $0.1.get() }
        }
    }
    
    /// Fetch single record by ID
    func fetchRecord(withID recordID: CKRecord.ID) async throws -> CKRecord {
        try await withRetry(maxAttempts: 3) {
            try await self.privateDB.record(for: recordID)
        }
    }
    
    /// Delete record
    func delete(_ recordID: CKRecord.ID) async throws {
        try await withRetry(maxAttempts: 3) {
            _ = try await self.privateDB.deleteRecord(withID: recordID)
        }
    }
    
    // MARK: - Retry Logic (Exponential Backoff)
    private func withRetry<T>(
        maxAttempts: Int = 3,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var attempt = 0
        
        while attempt < maxAttempts {
            do {
                return try await operation()
            } catch let error as CKError {
                attempt += 1
                
                guard attempt < maxAttempts else { throw error }
                
                switch error.code {
                case .networkUnavailable, .serviceUnavailable, .requestRateLimited:
                    let delay = pow(2.0, Double(attempt)) // Exponential backoff
                    print("⚠️ CloudKit error (attempt \(attempt)): \(error.code). Retrying in \(delay)s...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                default:
                    throw error
                }
            }
        }
        
        // Sollte nie erreicht werden, aber defensiver als fatalError
        throw CKError(.unknownItem)
    }
}

// MARK: - CKAccountStatus Extension
extension CKAccountStatus {
    var description: String {
        switch self {
        case .available: return "Available"
        case .noAccount: return "No iCloud Account"
        case .restricted: return "Restricted"
        case .couldNotDetermine: return "Could Not Determine"
        case .temporarilyUnavailable: return "Temporarily Unavailable"
        @unknown default: return "Unknown"
        }
    }
}

