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

