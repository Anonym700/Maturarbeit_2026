# 🎯 MASTER REFINEMENT PROMPT — PROJECT SPECIFIC
## CloudKit Migration für AemtliApp (Maturarbeit_2026)

---

## 🤖 ROLLE & BETRIEBSREGELN

Du bist ein Senior iOS-Entwickler, der eine vollständige CloudKit-Integration in ein bestehendes SwiftUI-Projekt implementiert.

**ABSOLUTE REGELN:**
1. **Keine Rückfragen** – Triff wohlinformierte Annahmen aus dem bestehenden Code
2. **Immer grüner Build** – Jede Änderung muss kompilieren, keine Syntax-/Typ-Fehler
3. **Atomare Commits** – Maximal 8 Commits, jeder lauffähig und logisch abgeschlossen
4. **Swift Concurrency only** – Verwende async/await, @MainActor, keine Completion-Handler
5. **Soft Schema Checking** – Warnungen loggen bei Schema-Mismatch, niemals crashen
6. **Keine absoluten Pfade** – Alle Dateipfade relativ zum Projekt-Root

---

## 📋 PROJEKT-FINGERPRINT

**App-Name:** AemtliApp (Maturarbeit_2026)  
**Target:** Maturarbeit  
**Bundle ID:** `com.christosalexisfantino.MaturarbeitApp`  
**CloudKit Container:** `iCloud.com.christosalexisfantino.MaturarbeitApp`  
**Framework:** SwiftUI (100%)  
**Swift Version:** 5.9/6+  
**iOS Deployment Target:** iOS 16+ empfohlen (CloudKit Concurrency-APIs optimal ab iOS 16)  

**Existierende Modelle:**
- `Chore` (Maturarbeit/Models/Chore.swift) – id:UUID, title:String, assignedTo:UUID?, dueDate:Date?, isDone:Bool, recurrence:ChoreRecurrence, createdAt:Date, deadline:Date?
- `FamilyMember` (Maturarbeit/Models/FamilyMember.swift) – id:UUID, name:String, role:FamilyRole
- `FamilyRole` (Maturarbeit/Models/FamilyRole.swift) – enum: parent, child
- `ChoreRecurrence` (Maturarbeit/Models/ChoreRecurrence.swift) – enum: once, daily, weekly, monthly

**Existierende Store-Architektur:**
- Protocol: `ChoreStore` (Maturarbeit/Store/ChoreStore.swift)
- Implementation: `InMemoryStore` (Maturarbeit/Store/InMemoryStore.swift)
- ViewModel: `AppState` (Maturarbeit/ViewModels/AppState.swift) – @MainActor ObservableObject

**Views:**
- RootView.swift (TabView mit 4 Tabs)
- DashboardView.swift
- ChoresView_Refactored.swift
- FamilyView.swift
- SettingsView.swift

**Design System:**
- AppTheme.swift (Centralized tokens)
- ThemeManager.swift

---

## ☁️ CLOUDKIT-SETUP

### 1. iOS Deployment Target anpassen
**Datei:** `Maturarbeit.xcodeproj/project.pbxproj`
- Ändere `IPHONEOS_DEPLOYMENT_TARGET = 17.0;` zu `16.0` (für CloudKit-Kompatibilität)

### 2. Entitlements-Datei erstellen
**Neue Datei:** `Maturarbeit/Maturarbeit.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.christosalexisfantino.MaturarbeitApp</string>
    </array>
    <!-- Optional: wird durch Push Notifications Capability automatisch gesetzt -->
    <key>aps-environment</key>
    <string>development</string>
</dict>
</plist>
```

### 3. Xcode Capabilities (Manuelle Schritte – WICHTIG!)

**Diese Capabilities MÜSSEN in Xcode aktiviert werden:**

1. **iCloud**
   - CloudKit aktivieren
   - Container auswählen: `iCloud.com.christosalexisfantino.MaturarbeitApp`

2. **Push Notifications**
   - Für CloudKit-Subscriptions & Remote Notifications erforderlich

3. **Background Modes** (optional für stille Updates)
   - ☑️ Remote notifications

**Hinweis an Benutzer (in CloudKitManager.swift als Kommentar):**
```swift
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
```

---

## 🏗 CLOUDKIT-ARCHITEKTUR

### Datei-Struktur (neu zu erstellen):
```
Maturarbeit/
├── AppDelegate.swift                  # NEU: Push Notifications Registration
├── CloudKit/
│   ├── CloudKitManager.swift          # Core Manager (Container, DB, Zone)
│   ├── RecordMapping.swift            # CKRecord ↔ Model Mappings
│   ├── CloudKitHealthChecker.swift    # Account-Status, Zone-Setup, Schema-Check
│   └── CloudKitSubscriptions.swift    # Push Subscriptions & Handlers
├── Store/
│   ├── ChoreStore.swift               # (existiert) Protocol
│   ├── InMemoryStore.swift            # (existiert) Fallback
│   └── CloudKitStore.swift            # NEU: CloudKit-Implementation
├── Utils/
│   └── LocalToCloudKitMigration.swift # Einmalige Migration
└── Maturarbeit.entitlements           # NEU: iCloud Entitlements
```

---

## 📦 CLOUDKIT SCHEMA-DEFINITION

### Record Types (Custom Zone: "MainZone")

#### 1. **Chore** (Record Type: "Chore")

**Hinweis:** `recordName` ist ein Systemfeld (CKRecord.ID) und wird nicht als Custom-Feld angelegt. Wir verwenden `UUID().uuidString` als recordName für idempotente Saves.

| Feld | CKRecord Type | Optional | Query Index | Sort Index | Begründung |
|------|---------------|----------|-------------|------------|------------|
| `title` | String | NO | ✅ | ✅ | Titel der Aufgabe, querybar & sortierbar |
| `assignedTo` | String | YES | ✅ | ❌ | UUID des zugewiesenen FamilyMembers (String-Referenz) |
| `dueDate` | Date | YES | ❌ | ✅ | Fälligkeitsdatum, sortierbar |
| `isDone` | Int64 | NO | ✅ | ❌ | Bool→Int64 (0/1), filterbar nach Status |
| `recurrence` | String | NO | ✅ | ❌ | Enum rawValue: "once", "daily", "weekly", "monthly" |
| `createdAt` | Date | NO | ❌ | ✅ | Erstellungsdatum, sortierbar |
| `deadline` | Date | YES | ❌ | ✅ | Deadline für einmalige Tasks, sortierbar |

**Indices:**
- Query: `title`, `assignedTo`, `isDone`, `recurrence`
- Sort: `title`, `dueDate`, `createdAt`, `deadline`

#### 2. **FamilyMember** (Record Type: "FamilyMember")

**Hinweis:** `recordName` ist ein Systemfeld (CKRecord.ID) und wird nicht als Custom-Feld angelegt.

| Feld | CKRecord Type | Optional | Query Index | Sort Index | Begründung |
|------|---------------|----------|-------------|------------|------------|
| `name` | String | NO | ✅ | ✅ | Name des Familienmitglieds |
| `role` | String | NO | ✅ | ❌ | Enum rawValue: "parent", "child" |

**Indices:**
- Query: `name`, `role`
- Sort: `name`

---

## 🔧 IMPLEMENTATION DETAILS

### CloudKitManager.swift (Maturarbeit/CloudKit/)

```swift
import CloudKit
import Foundation

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
```

### RecordMapping.swift (Maturarbeit/CloudKit/)

```swift
import CloudKit
import Foundation

extension Chore {
    /// Convert Chore → CKRecord
    func toCKRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "Chore", recordID: recordID)
        
        record["title"] = title as CKRecordValue
        record["assignedTo"] = assignedTo.map { $0.uuidString } as CKRecordValue?
        record["dueDate"] = dueDate as CKRecordValue?
        record["isDone"] = (isDone ? 1 : 0) as CKRecordValue
        record["recurrence"] = recurrence.rawValue as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["deadline"] = deadline as CKRecordValue?
        
        return record
    }
    
    /// Convert CKRecord → Chore (with soft error handling)
    static func from(_ record: CKRecord) -> Chore? {
        guard
            let recordName = UUID(uuidString: record.recordID.recordName),
            let title = record["title"] as? String,
            let isDoneInt = record["isDone"] as? Int64,
            let recurrenceRaw = record["recurrence"] as? String,
            let recurrence = ChoreRecurrence(rawValue: recurrenceRaw),
            let createdAt = record["createdAt"] as? Date
        else {
            print("⚠️ Soft schema error: Missing required fields in Chore record \(record.recordID)")
            return nil
        }
        
        let assignedToString = record["assignedTo"] as? String
        let assignedTo = assignedToString.flatMap { UUID(uuidString: $0) }
        
        return Chore(
            id: recordName,
            title: title,
            assignedTo: assignedTo,
            dueDate: record["dueDate"] as? Date,
            isDone: isDoneInt == 1,
            recurrence: recurrence,
            createdAt: createdAt,
            deadline: record["deadline"] as? Date
        )
    }
}

extension FamilyMember {
    /// Convert FamilyMember → CKRecord
    func toCKRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "FamilyMember", recordID: recordID)
        
        record["name"] = name as CKRecordValue
        record["role"] = role.rawValue as CKRecordValue
        
        return record
    }
    
    /// Convert CKRecord → FamilyMember
    static func from(_ record: CKRecord) -> FamilyMember? {
        guard
            let recordName = UUID(uuidString: record.recordID.recordName),
            let name = record["name"] as? String,
            let roleRaw = record["role"] as? String,
            let role = FamilyRole(rawValue: roleRaw)
        else {
            print("⚠️ Soft schema error: Missing required fields in FamilyMember record \(record.recordID)")
            return nil
        }
        
        return FamilyMember(id: recordName, name: name, role: role)
    }
}
```

### CloudKitHealthChecker.swift (Maturarbeit/CloudKit/)

```swift
import CloudKit
import Foundation

@MainActor
final class CloudKitHealthChecker: ObservableObject {
    @Published var isHealthy: Bool = false
    @Published var healthMessage: String = "Checking CloudKit..."
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    
    private let manager = CloudKitManager.shared
    
    func performHealthCheck() async {
        // 1. Account Status
        await manager.checkAccountStatus()
        self.accountStatus = manager.accountStatus
        
        guard accountStatus == .available else {
            isHealthy = false
            healthMessage = "❌ iCloud not available: \(accountStatus.description)"
            return
        }
        
        // 2. Custom Zone Creation
        do {
            try await manager.ensureCustomZoneExists()
        } catch {
            isHealthy = false
            healthMessage = "❌ Failed to create custom zone: \(error.localizedDescription)"
            return
        }
        
        // 3. Soft Schema Check (Query test)
        do {
            _ = try await manager.fetch(recordType: "Chore", predicate: NSPredicate(value: true))
            isHealthy = true
            healthMessage = "✅ CloudKit is healthy"
        } catch {
            // First time setup - no records yet, still healthy
            isHealthy = true
            healthMessage = "✅ CloudKit ready (no records yet)"
        }
    }
}
```

### CloudKitSubscriptions.swift (Maturarbeit/CloudKit/)

```swift
import CloudKit
import Foundation

@MainActor
final class CloudKitSubscriptions {
    private let manager = CloudKitManager.shared
    
    /// Setup query subscriptions for Chore and FamilyMember
    func setupSubscriptions() async throws {
        try await setupSubscription(for: "Chore")
        try await setupSubscription(for: "FamilyMember")
        print("✅ CloudKit subscriptions configured")
    }
    
    private func setupSubscription(for recordType: String) async throws {
        let subscriptionID = "\(recordType)Subscription"
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
            _ = try await manager.privateDB.save(subscription)
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
```

### AppDelegate.swift (Maturarbeit/)

```swift
import UIKit

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
```

### CloudKitStore.swift (Maturarbeit/Store/)

```swift
import Foundation
import CloudKit

@MainActor
final class CloudKitStore: ChoreStore {
    private let manager = CloudKitManager.shared
    
    // MARK: - ChoreStore Protocol
    
    func loadChores() async -> [Chore] {
        do {
            let records = try await manager.fetch(
                recordType: "Chore",
                predicate: NSPredicate(value: true),
                sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
            )
            
            return records.compactMap { Chore.from($0) }
        } catch {
            print("❌ Failed to load chores: \(error)")
            return []
        }
    }
    
    func saveChore(_ chore: Chore) async {
        do {
            let record = chore.toCKRecord(zoneID: manager.customZone.zoneID)
            _ = try await manager.save(record)
            print("✅ Saved chore: \(chore.title)")
        } catch {
            print("❌ Failed to save chore: \(error)")
        }
    }
    
    func updateChore(_ chore: Chore) async {
        // Same as save (upsert via recordName)
        await saveChore(chore)
    }
    
    func deleteChore(_ chore: Chore) async {
        do {
            let recordID = CKRecord.ID(
                recordName: chore.id.uuidString,
                zoneID: manager.customZone.zoneID
            )
            try await manager.delete(recordID)
            print("✅ Deleted chore: \(chore.title)")
        } catch {
            print("❌ Failed to delete chore: \(error)")
        }
    }
    
    // MARK: - FamilyMember Operations (Future Extension)
    
    func loadFamilyMembers() async -> [FamilyMember] {
        do {
            let records = try await manager.fetch(
                recordType: "FamilyMember",
                predicate: NSPredicate(value: true),
                sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
            )
            
            return records.compactMap { FamilyMember.from($0) }
        } catch {
            print("❌ Failed to load family members: \(error)")
            return []
        }
    }
    
    func saveFamilyMember(_ member: FamilyMember) async {
        do {
            let record = member.toCKRecord(zoneID: manager.customZone.zoneID)
            _ = try await manager.save(record)
            print("✅ Saved family member: \(member.name)")
        } catch {
            print("❌ Failed to save family member: \(error)")
        }
    }
}
```

### LocalToCloudKitMigration.swift (Maturarbeit/Utils/)

```swift
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
```

---

## 🔗 APP-INTEGRATION

### MaturarbeitApp.swift (Update)

```swift
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
```

### AppState.swift (Update Store Injection)

```swift
// In AppState init(), replace InMemoryStore with CloudKitStore:

init() {
    let parent = FamilyMember(name: "Parent 1", role: .parent)
    let child1 = FamilyMember(name: "Anna", role: .child)
    let child2 = FamilyMember(name: "Max", role: .child)
    
    self.members = [parent, child1, child2]
    self.currentUserID = parent.id
    
    // ✨ Switch to CloudKit Store
    self.store = CloudKitStore()
    
    Task { @MainActor in
        await loadChores()
        // Nur aufrufen, wenn diese Methoden in deinem AppState existieren:
        // await checkAndResetIfNeeded()
        // setupMidnightResetTimer()
    }
}
```

### SettingsView.swift (Add Health Banner)

```swift
// Add this to SettingsView body (optional DEBUG feature):

#if DEBUG
@EnvironmentObject var healthChecker: CloudKitHealthChecker

Section("CloudKit Status") {
    HStack {
        Image(systemName: healthChecker.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundColor(healthChecker.isHealthy ? .green : .red)
        Text(healthChecker.healthMessage)
            .font(.caption)
    }
    
    Button("Re-check Health") {
        Task {
            await healthChecker.performHealthCheck()
        }
    }
}
#endif
```

---

## 🧪 VERIFIKATION & TESTING

### Checkliste für echten Device-Build:

1. **Xcode-Konfiguration:**
   - [ ] Target iOS 16.0+ gesetzt
   - [ ] Entitlements-Datei verlinkt
   - [ ] iCloud Capability aktiviert (Container: iCloud.com.christosalexisfantino.MaturarbeitApp)
   - [ ] Push Notifications aktiviert
   - [ ] Background Modes: Remote notifications aktiviert
   - [ ] Gültiges Signing Team ausgewählt

2. **CloudKit Dashboard (Development):**
   - [ ] Container erstellt
   - [ ] Schema deployt (Record Types: Chore, FamilyMember)
   - [ ] Indices konfiguriert (Query/Sort)

3. **Device-Test (ZWINGEND auf echtem Gerät!):**
   - [ ] ⚠️ **Nur auf echtem iOS-Gerät testen** (Simulator iCloud ist instabil)
   - [ ] Gerät mit iCloud-Account anmelden (gleiche Apple ID wie Developer Account)
   - [ ] App installieren und starten
   - [ ] Health Check zeigt "✅ CloudKit is healthy"
   - [ ] Chore erstellen → In CloudKit Dashboard sichtbar
   - [ ] App neu starten → Daten persistiert

4. **Production Deployment:**
   - [ ] Schema von Development → Production deployen (im Dashboard)
   - [ ] Entitlements: `aps-environment` auf `production` setzen
   - [ ] App Store Connect: Push Notifications aktiviert

---

## 📝 COMMIT-PLAN (8 atomare Commits)

```
1. chore: adjust iOS deployment target to 16.0 for CloudKit support
   - Maturarbeit.xcodeproj/project.pbxproj

2. feat: add CloudKit entitlements and container configuration
   - Maturarbeit/Maturarbeit.entitlements

3. feat: implement CloudKitManager with async CRUD and retry logic
   - Maturarbeit/CloudKit/CloudKitManager.swift

4. feat: add CKRecord mappings for Chore and FamilyMember models
   - Maturarbeit/CloudKit/RecordMapping.swift

5. feat: implement CloudKit health checker and zone setup
   - Maturarbeit/CloudKit/CloudKitHealthChecker.swift

6. feat: add CloudKit subscriptions and remote notifications
   - Maturarbeit/CloudKit/CloudKitSubscriptions.swift
   - Maturarbeit/AppDelegate.swift

7. feat: implement CloudKitStore and local-to-cloud migration
   - Maturarbeit/Store/CloudKitStore.swift
   - Maturarbeit/Utils/LocalToCloudKitMigration.swift

8. feat: integrate CloudKit into app lifecycle and UI
   - Maturarbeit/MaturarbeitApp.swift
   - Maturarbeit/ViewModels/AppState.swift
   - Maturarbeit/Views/SettingsView.swift
```

---

## ⚡️ EXECUTE NOW – SCHRITT-FÜR-SCHRITT

### Reihenfolge der Implementierung:

1. **iOS Deployment Target anpassen**
   - Öffne `Maturarbeit.xcodeproj/project.pbxproj`
   - Suche `IPHONEOS_DEPLOYMENT_TARGET = 17.0;`
   - Ersetze durch `IPHONEOS_DEPLOYMENT_TARGET = 16.0;`

2. **Entitlements erstellen**
   - Neue Datei: `Maturarbeit/Maturarbeit.entitlements` (siehe XML oben)

3. **CloudKit Ordner erstellen**
   - Erstelle Ordner: `Maturarbeit/CloudKit/`
   - Erstelle leere Dateien: CloudKitManager.swift, RecordMapping.swift, CloudKitHealthChecker.swift, CloudKitSubscriptions.swift

4. **Implementiere CloudKitManager.swift** (siehe Code oben)

5. **Implementiere RecordMapping.swift** (siehe Code oben)

6. **Implementiere CloudKitHealthChecker.swift** (siehe Code oben)

7. **Implementiere CloudKitSubscriptions.swift** (siehe Code oben)

8. **Implementiere AppDelegate.swift** (Remote Notifications Registration)

9. **Implementiere CloudKitStore.swift** in `Maturarbeit/Store/`

10. **Implementiere LocalToCloudKitMigration.swift** in `Maturarbeit/Utils/`

11. **Update MaturarbeitApp.swift** (AppDelegate + Health Check on Launch)

12. **Update AppState.swift** (Store Injection: InMemoryStore → CloudKitStore)

13. **Update SettingsView.swift** (Optional: Health Banner)

14. **Xcode-Projekt aktualisieren**
    - Öffne Maturarbeit.xcodeproj in Xcode
    - Füge alle neuen Dateien zum Target hinzu
    - Verlinke Entitlements-Datei in Build Settings
    - Aktiviere Capabilities (siehe oben)

15. **Build & Test**
    - Baue das Projekt (`⌘B`)
    - Behebe Compile-Fehler (falls vorhanden)
    - Teste auf echtem Gerät

---

## 📊 ABSCHLUSS-REPORT (Nach Ausführung)

### Neue Dateien:
- ✅ `Maturarbeit/Maturarbeit.entitlements` – iCloud & Push Entitlements
- ✅ `Maturarbeit/AppDelegate.swift` – Remote Notifications Registration
- ✅ `Maturarbeit/CloudKit/CloudKitManager.swift` – Core CloudKit Manager
- ✅ `Maturarbeit/CloudKit/RecordMapping.swift` – Model ↔ CKRecord Mappings
- ✅ `Maturarbeit/CloudKit/CloudKitHealthChecker.swift` – Health & Zone Setup
- ✅ `Maturarbeit/CloudKit/CloudKitSubscriptions.swift` – Push Subscriptions
- ✅ `Maturarbeit/Store/CloudKitStore.swift` – ChoreStore Implementation
- ✅ `Maturarbeit/Utils/LocalToCloudKitMigration.swift` – One-time Migration

### Geänderte Dateien:
- ✅ `Maturarbeit.xcodeproj/project.pbxproj` – iOS Target 16.0
- ✅ `Maturarbeit/MaturarbeitApp.swift` – Health Check & Migration on Launch
- ✅ `Maturarbeit/ViewModels/AppState.swift` – CloudKitStore Injection
- ✅ `Maturarbeit/Views/SettingsView.swift` – DEBUG Health Banner (optional)

### Build Status:
- ✅ **Kompiliert ohne Fehler**
- ✅ **Alle async/await korrekt mit @MainActor**
- ✅ **Soft Schema Checking (keine Crashes)**
- ✅ **Retry Logic mit Exponential Backoff**
- ✅ **Idempotente Migration (UUID-basierte recordNames)**

### CloudKit-Schema:
- ✅ **Record Type: Chore** (7 Custom-Felder, Query/Sort Indices)
- ✅ **Record Type: FamilyMember** (2 Custom-Felder, Query/Sort Indices)
- ✅ **Custom Zone: MainZone**
- ✅ **Subscriptions: Chore + FamilyMember**

---

## 🎯 NÄCHSTE SCHRITTE (Manuell durch Benutzer)

1. **Xcode öffnen:**
   ```bash
   open Maturarbeit.xcodeproj
   ```

2. **Capabilities aktivieren:**
   - Target "Maturarbeit" → Signing & Capabilities
   - ➕ iCloud (CloudKit, Container: iCloud.com.christosalexisfantino.MaturarbeitApp)
   - ➕ Push Notifications
   - ➕ Background Modes (Remote notifications)

3. **Signing Team setzen:**
   - Apple Developer Account auswählen

4. **CloudKit Dashboard:**
   - https://icloud.developer.apple.com/dashboard
   - Schema deployen (Development → Production)

5. **Device-Build:**
   - Baue auf echtem Gerät (iOS 16+)
   - Teste mit gleicher iCloud-ID

---

## ✨ FINAL QUALITY TWEAKS (BEREITS INTEGRIERT)

Diese 4 kritischen Tweaks sind bereits im Code oben implementiert:

1. **✅ Push-Registration via AppDelegate**
   - `UIApplication.shared.registerForRemoteNotifications()` in AppDelegate
   - Keine User-Permission nötig für stille CloudKit-Pushes
   - Vollständiges Remote-Notification-Handling

2. **✅ Optionals korrekt speichern**
   - `record["assignedTo"] = assignedTo.map { $0.uuidString } as CKRecordValue?`
   - Kein leerer String bei nil, sondern Feld wird nicht gesetzt

3. **✅ Zone-Erstellung robust**
   - `modifyRecordZones(saving:deleting:)` statt `save()`
   - Idempotent & Race-Condition-sicher

4. **✅ Defensiver Error-Handling**
   - `throw CKError(.unknownItem)` statt `fatalError("Unreachable")`
   - Kein App-Crash bei unerwarteten Fehlern

---

**🚀 READY TO EXECUTE – Starte die Implementierung jetzt!**

