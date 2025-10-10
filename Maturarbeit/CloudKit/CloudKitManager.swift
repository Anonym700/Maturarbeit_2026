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
    let sharedDB: CKDatabase
    let customZone: CKRecordZone
    
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isHealthy: Bool = false
    
    /// Update health status based on account status
    private func updateHealthStatus() {
        isHealthy = accountStatus.isHealthy
        print("🏥 Health status updated: \(isHealthy ? "Healthy" : "Unhealthy")")
    }
    @Published var currentUserRecordID: CKRecord.ID?
    @Published var activeShare: CKShare?
    @Published var isShareOwner: Bool = false
    @Published private(set) var sharedZoneID: CKRecordZone.ID?
    
    // MARK: - UserDefaults Keys for Persistence
    private let shareStateKey = "CloudKitActiveShareState"
    private let shareOwnerKey = "CloudKitIsShareOwner"
    private let sharedZoneIDKey = "CloudKitSharedZoneID"
    
    // MARK: - Configuration
    private let containerID = "iCloud.com.christosalexisfantino.MaturarbeitApp"
    private let customZoneName = "MainZone"
    private let familyRootRecordName = "FamilyRoot"
    
    private init() {
        self.container = CKContainer(identifier: containerID)
        self.privateDB = container.privateCloudDatabase
        self.sharedDB = container.sharedCloudDatabase
        self.customZone = CKRecordZone(zoneName: customZoneName)
        
        print("☁️ CloudKit initialized with Private and Shared Database: \(containerID)")
        
        // Try to restore share state from UserDefaults
        restoreShareStateFromDefaults()
    }
    
    // MARK: - Share State Persistence
    
    /// Save share state to UserDefaults for persistence across app restarts
    private func saveShareStateToDefaults() {
        do {
            if let share = activeShare {
                // Save share URL as string
                if let url = share.url {
                    UserDefaults.standard.set(url.absoluteString, forKey: shareStateKey)
                    print("💾 Saved share URL to UserDefaults: \(url)")
                }
                
                // Save ownership state
                UserDefaults.standard.set(isShareOwner, forKey: shareOwnerKey)
                print("💾 Saved ownership state: \(isShareOwner)")
                
                // Save shared zone ID
                if let zoneID = sharedZoneID {
                    UserDefaults.standard.set(zoneID.zoneName, forKey: sharedZoneIDKey)
                    print("💾 Saved zone ID: \(zoneID.zoneName)")
                }
                
                // Force synchronization
                UserDefaults.standard.synchronize()
            } else {
                // Clear saved state
                UserDefaults.standard.removeObject(forKey: shareStateKey)
                UserDefaults.standard.removeObject(forKey: shareOwnerKey)
                UserDefaults.standard.removeObject(forKey: sharedZoneIDKey)
                UserDefaults.standard.synchronize()
                print("💾 Cleared share state from UserDefaults")
            }
        } catch {
            print("⚠️ Failed to save share state to UserDefaults: \(error)")
        }
    }
    
    /// Restore share state from UserDefaults (lightweight, doesn't fetch from CloudKit)
    private func restoreShareStateFromDefaults() {
        // Only restore the flags, actual share will be fetched via checkForSharedFamily
        if let savedURL = UserDefaults.standard.string(forKey: shareStateKey) {
            isShareOwner = UserDefaults.standard.bool(forKey: shareOwnerKey)
            
            if let zoneName = UserDefaults.standard.string(forKey: sharedZoneIDKey) {
                // Note: We can't fully recreate CKRecordZone.ID without owner name
                // So we'll rely on checkForSharedFamily to set the correct zoneID
                print("💾 Found saved share state in UserDefaults (owner: \(isShareOwner), zone: \(zoneName))")
                print("   Saved URL: \(savedURL)")
            } else {
                print("💾 Found saved share state in UserDefaults (owner: \(isShareOwner))")
                print("   Saved URL: \(savedURL)")
            }
        } else {
            print("💾 No saved share state found in UserDefaults")
        }
    }
    
    // MARK: - Health Check
    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            self.accountStatus = status
            print("☁️ Account Status: \(status.description)")
            
            // Update health status
            updateHealthStatus()
            
            // Also check if we have a current user record ID
            if status == .available {
                do {
                    let userID = try await fetchCurrentUserRecordID()
                    print("👤 Current user record ID: \(userID.recordName)")
                } catch {
                    print("⚠️ Could not fetch current user record ID: \(error)")
                }
            }
        } catch {
            print("❌ Failed to check account status: \(error)")
            self.accountStatus = .couldNotDetermine
            updateHealthStatus()
        }
    }
    
    // MARK: - User Identification
    /// Fetch the current iCloud user's record ID
    func fetchCurrentUserRecordID() async throws -> CKRecord.ID {
        let userRecordID = try await container.userRecordID()
        self.currentUserRecordID = userRecordID
        print("👤 Current iCloud User ID: \(userRecordID.recordName)")
        print("   Zone: \(userRecordID.zoneID.zoneName)")
        print("   Record ID: \(userRecordID)")
        return userRecordID
    }
    
    
    // MARK: - Family Sharing with CKShare
    
    /// The zone ID to use for operations (owner: private custom zone, participant: shared zone)
    var currentZoneID: CKRecordZone.ID {
        if let zone = sharedZoneID, activeShare != nil && !isShareOwner {
            return zone
        }
        return customZone.zoneID
    }
    
    /// Get the FamilyRoot record ID for linking child records
    func getFamilyRootRecordID() -> CKRecord.ID {
        return CKRecord.ID(recordName: familyRootRecordName, zoneID: currentZoneID)
    }
    
    /// Create or get the root record for family sharing
    private func getOrCreateFamilyRoot() async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: familyRootRecordName, zoneID: customZone.zoneID)
        
        // Try to fetch existing root
        do {
            let existingRoot = try await privateDB.record(for: recordID)
            return existingRoot
        } catch {
            // Create new root if it doesn't exist
            let newRoot = CKRecord(recordType: "FamilyRoot", recordID: recordID)
            newRoot["createdAt"] = Date() as CKRecordValue
            
            let savedRoot = try await save(newRoot)
            return savedRoot
        }
    }
    
    /// Create a share for the family (Parent only)
    /// - Parameter forceNew: when true, do not reuse an existing share reference
    func createFamilyShare(forceNew: Bool = false) async throws -> CKShare {
        // Get or create the family root record
        let rootRecord = try await getOrCreateFamilyRoot()
        
        // Check if share already exists
        if !forceNew, let existingShare = try? await fetchExistingShare(for: rootRecord) {
            self.activeShare = existingShare
            self.isShareOwner = true
            self.sharedZoneID = existingShare.recordID.zoneID
            return existingShare
        }
        
        // Create new share with correct permissions for participant-based sharing
        let share = CKShare(rootRecord: rootRecord)
        share[CKShare.SystemFieldKey.title] = "Family Chores" as CKRecordValue
        // Allow anyone with the link to join with read/write access
        share.publicPermission = .readWrite
        
        // Set the default participant permission (for invited users)
        share[CKShare.SystemFieldKey.shareType] = "com.christosalexisfantino.familyshare" as CKRecordValue
        
        // Save both the root record and share together
        let (records, _) = try await privateDB.modifyRecords(
            saving: [rootRecord, share],
            deleting: [],
            savePolicy: .changedKeys
        )
        
        guard let savedShare = records.compactMap({ try? $0.1.get() as? CKShare }).first else {
            throw CKError(.unknownItem)
        }
        
        self.activeShare = savedShare
        self.isShareOwner = true
        self.sharedZoneID = savedShare.recordID.zoneID
        
        // Persist share state
        saveShareStateToDefaults()
        
        return savedShare
    }
    
    /// Fetch existing share for a record
    private func fetchExistingShare(for record: CKRecord) async throws -> CKShare? {
        guard let shareReference = record.share else {
            return nil
        }
        
        let share = try await privateDB.record(for: shareReference.recordID) as? CKShare
        if let share = share {
            self.sharedZoneID = share.recordID.zoneID
        }
        return share
    }
    
    /// Delete existing share (for debugging/reset)
    func deleteExistingShare() async throws {
        let recordID = CKRecord.ID(recordName: familyRootRecordName, zoneID: customZone.zoneID)
        
        do {
            // Try to fetch the FamilyRoot record
            let record = try await privateDB.record(for: recordID)
            
            // If it has a share, delete both the share and the root
            if let shareRef = record.share {
                _ = try await privateDB.modifyRecords(saving: [], deleting: [shareRef.recordID, recordID])
            } else {
                // Just delete the root record
                _ = try await privateDB.deleteRecord(withID: recordID)
            }
            
            self.activeShare = nil
            self.isShareOwner = false
            self.sharedZoneID = nil
            
            // Clear saved state
            saveShareStateToDefaults()
        } catch {
            // No existing share to delete
        }
    }
    
    /// Get the share URL to send to family members
    /// - Parameter forceNew: when true, create a brand new share even if one exists
    func getFamilyShareURL(forceNew: Bool = false) async throws -> URL {
        if forceNew || activeShare == nil {
            // Create share if it doesn't exist or when forcing a new one
            let newShare = try await createFamilyShare(forceNew: forceNew)
            guard let url = newShare.url else {
                throw CKError(.unknownItem)
            }
            return url
        }
        guard let share = activeShare else { throw CKError(.unknownItem) }
        
        guard let url = share.url else {
            throw CKError(.unknownItem)
        }
        
        return url
    }
    
    /// Check if user has access to a shared family
    /// CRITICAL: This must work reliably for both owner and participant after app restart
    func checkForSharedFamily() async throws {
        // STRATEGY 1: Check if we own a share (in private DB)
        if let share = try await checkOwnedShare() {
            self.activeShare = share
            self.isShareOwner = true
            self.sharedZoneID = share.recordID.zoneID
            saveShareStateToDefaults()
            return
        }
        
        // STRATEGY 2: Check if we're a participant (in shared DB)
        // Try multiple approaches since CloudKit can be unreliable
        if let share = try await checkParticipantShare() {
            self.activeShare = share
            self.isShareOwner = false
            self.sharedZoneID = share.recordID.zoneID
            saveShareStateToDefaults()
            return
        }
        
        // STRATEGY 3: Check UserDefaults - if we had a share before, try to restore it
        if let savedURL = UserDefaults.standard.string(forKey: shareStateKey),
           let url = URL(string: savedURL) {
            do {
                // Try to fetch the share directly via URL
                let metadata: CKShare.Metadata = try await withCheckedThrowingContinuation { continuation in
                    let op = CKFetchShareMetadataOperation(shareURLs: [url])
                    var fetched: CKShare.Metadata?
                    op.perShareMetadataBlock = { _, meta, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        fetched = meta
                    }
                    op.fetchShareMetadataResultBlock = { result in
                        switch result {
                        case .failure(let err):
                            continuation.resume(throwing: err)
                        case .success:
                            if let fetched = fetched {
                                continuation.resume(returning: fetched)
                            } else {
                                continuation.resume(throwing: CKError(.unknownItem))
                            }
                        }
                    }
                    container.add(op)
                }
                
                // Fetch the actual share
                let share = try await sharedDB.record(for: metadata.share.recordID) as? CKShare
                if let share = share {
                    self.activeShare = share
                    self.isShareOwner = false
                    self.sharedZoneID = share.recordID.zoneID
                    saveShareStateToDefaults()
                    return
                }
            } catch {
                // Failed to restore from saved URL
            }
        }
        
        self.activeShare = nil
        self.isShareOwner = false
        self.sharedZoneID = nil
        saveShareStateToDefaults()
    }
    
    /// Check if we own a share in the private database
    private func checkOwnedShare() async throws -> CKShare? {
        print("   Checking private DB for owned share...")
        let recordID = CKRecord.ID(recordName: familyRootRecordName, zoneID: customZone.zoneID)
        
        do {
            let record = try await privateDB.record(for: recordID)
            
            if let shareRef = record.share {
                let share = try await privateDB.record(for: shareRef.recordID) as? CKShare
                print("   Found share in private DB with \(share?.participants.count ?? 0) participants")
                return share
            } else {
                print("   Private DB record found but no share attached")
            }
        } catch {
            print("   No owned share found in private DB: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Check if we're a participant in a shared family (in shared DB)
    /// Uses multiple strategies to find the share reliably
    private func checkParticipantShare() async throws -> CKShare? {
        print("   Checking shared DB as participant...")
        
        // APPROACH 1: Query for FamilyRoot records
        do {
            let query = CKQuery(recordType: "FamilyRoot", predicate: NSPredicate(value: true))
            let (matches, _) = try await sharedDB.records(matching: query)
            
            print("   Found \(matches.count) FamilyRoot records in shared DB")
            
            for (_, result) in matches {
                if let record = try? result.get(),
                   let shareRef = record.share,
                   let share = try? await sharedDB.record(for: shareRef.recordID) as? CKShare {
                    print("   Found share via FamilyRoot query")
                    print("   Share participants: \(share.participants.count)")
                    return share
                }
            }
        } catch {
            print("   FamilyRoot query failed: \(error.localizedDescription)")
        }
        
        // APPROACH 2: Query for ANY shared records (Chore, FamilyMember)
        // Sometimes FamilyRoot isn't synced but child records are
        for recordType in ["Chore", "FamilyMember"] {
            do {
                let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
                let (matches, _) = try await sharedDB.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1)
                
                if let firstRecord = matches.first {
                    if let record = try? firstRecord.1.get() {
                        // Get the zone ID from this record
                        let zoneID = record.recordID.zoneID
                        print("   Found shared record of type \(recordType) in zone: \(zoneID.zoneName)")
                        
                        // Try to fetch the FamilyRoot from the same zone
                        let rootID = CKRecord.ID(recordName: familyRootRecordName, zoneID: zoneID)
                        if let rootRecord = try? await sharedDB.record(for: rootID),
                           let shareRef = rootRecord.share,
                           let share = try? await sharedDB.record(for: shareRef.recordID) as? CKShare {
                            print("   Found share via \(recordType) → FamilyRoot")
                            print("   Share participants: \(share.participants.count)")
                            return share
                        }
                    }
                }
            } catch {
                print("   \(recordType) query failed: \(error.localizedDescription)")
            }
        }
        
        print("   No participant share found in shared DB")
        return nil
    }
    
    /// Accept a share (called automatically when user opens share link)
    func acceptShare(metadata: CKShare.Metadata) async throws {
        let share = try await container.accept(metadata)
        self.activeShare = share
        self.sharedZoneID = share.recordID.zoneID
        
        // Determine if user is owner
        let currentUserID = try await fetchCurrentUserRecordID()
        self.isShareOwner = share.owner.userIdentity.userRecordID == currentUserID
        
        // Persist share state
        saveShareStateToDefaults()
        
        print("✅ Accepted family share - Owner: \(isShareOwner)")
        print("   Share participants: \(share.participants.count)")
        print("   Share ID: \(share.recordID.recordName)")
    }
    
    /// Accept a share by fetching metadata for a given URL (bypasses system URL mapping)
    func acceptShare(from url: URL) async throws {
        print("🔗 Accepting share from URL: \(url)")
        
        // Fetch share metadata via operation API
        let metadata: CKShare.Metadata = try await withCheckedThrowingContinuation { continuation in
            let op = CKFetchShareMetadataOperation(shareURLs: [url])
            var fetched: CKShare.Metadata?
            op.perShareMetadataBlock = { _, meta, error in
                if let error = error { return continuation.resume(throwing: error) }
                fetched = meta
            }
            op.fetchShareMetadataResultBlock = { result in
                switch result {
                case .failure(let err):
                    continuation.resume(throwing: err)
                case .success:
                    guard let fetched else {
                        continuation.resume(throwing: CKError(.unknownItem))
                        return
                    }
                    continuation.resume(returning: fetched)
                }
            }
            self.container.add(op)
        }
        
        print("✅ Fetched share metadata, accepting share...")
        try await acceptShare(metadata: metadata)
    }
    
    /// Get all participants of the current share
    func getShareParticipants() async -> [CKShare.Participant] {
        guard let share = activeShare else { 
            return [] 
        }
        
        return share.participants
    }
    
    /// Determine user role based on share ownership
    var userRole: FamilyRole {
        // CRITICAL FIX: Use isShareOwner to determine role correctly
        // isShareOwner is true when we created the share (Parent)
        // isShareOwner is false when we joined the share (Child)
        return isShareOwner ? .parent : .child
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
    
    /// Save single record with conflict resolution (uses correct database based on share)
    func save(_ record: CKRecord) async throws -> CKRecord {
        let policy: CKModifyRecordsOperation.RecordSavePolicy = .changedKeys
        
        // Use private database if we own the share or have no share
        // Only use shared database if we're explicitly a participant (not owner)
        let database = (activeShare != nil && !isShareOwner) ? sharedDB : privateDB
        
        print("💾 Saving record \(record.recordType) to \(database == privateDB ? "private" : "shared") database")
        
        return try await withRetry(maxAttempts: 3) {
            let (results, _) = try await database.modifyRecords(
                saving: [record],
                deleting: [],
                savePolicy: policy
            )
            
            guard let savedRecord = try results.first?.1.get() else {
                throw CKError(.unknownItem)
            }
            print("✅ Successfully saved record \(savedRecord.recordType)")
            return savedRecord
        }
    }
    
    /// Fetch records by query (uses correct database based on share)
    func fetch(
        recordType: String,
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor] = []
    ) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors
        
        // Use private database if we own the share or have no share
        // Only use shared database if we're explicitly a participant (not owner)
        let database = (activeShare != nil && !isShareOwner) ? sharedDB : privateDB
        
        print("🔍 Fetching \(recordType) records from \(database == privateDB ? "private" : "shared") database")
        
        return try await withRetry(maxAttempts: 3) {
            let (matches, _) = try await database.records(
                matching: query,
                inZoneWith: self.currentZoneID
            )
            let records = matches.compactMap { try? $0.1.get() }
            print("✅ Found \(records.count) \(recordType) records")
            return records
        }
    }
    
    /// Fetch single record by ID
    func fetchRecord(withID recordID: CKRecord.ID) async throws -> CKRecord {
        let database = (activeShare != nil && !isShareOwner) ? sharedDB : privateDB
        print("🔍 Fetching record \(recordID.recordName) from \(database == privateDB ? "private" : "shared") database")
        return try await withRetry(maxAttempts: 3) {
            let record = try await database.record(for: recordID)
            print("✅ Successfully fetched record \(record.recordType)")
            return record
        }
    }
    
    /// Delete record (uses correct database based on share)
    func delete(_ recordID: CKRecord.ID) async throws {
        let database = (activeShare != nil && !isShareOwner) ? sharedDB : privateDB
        print("🗑️ Deleting record \(recordID.recordName) from \(database == privateDB ? "private" : "shared") database")
        try await withRetry(maxAttempts: 3) {
            _ = try await database.deleteRecord(withID: recordID)
            print("✅ Successfully deleted record \(recordID.recordName)")
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
                
                guard attempt < maxAttempts else { 
                    print("❌ CloudKit error after \(maxAttempts) attempts: \(error.code)")
                    throw error 
                }
                
                switch error.code {
                case .networkUnavailable, .serviceUnavailable, .requestRateLimited:
                    let delay = pow(2.0, Double(attempt)) // Exponential backoff
                    print("⚠️ CloudKit error (attempt \(attempt)): \(error.code). Retrying in \(delay)s...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                default:
                    print("❌ CloudKit error (attempt \(attempt)): \(error.code). Not retrying.")
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
    
    var isHealthy: Bool {
        return self == .available
    }
}

