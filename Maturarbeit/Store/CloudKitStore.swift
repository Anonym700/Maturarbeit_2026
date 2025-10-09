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

