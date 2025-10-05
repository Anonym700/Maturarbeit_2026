//
//  FamilyMember.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import Foundation

struct FamilyMember: Identifiable, Hashable {
    let id: UUID
    let name: String
    let role: FamilyRole
    
    init(id: UUID = UUID(), name: String, role: FamilyRole) {
        self.id = id
        self.name = name
        self.role = role
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FamilyMember, rhs: FamilyMember) -> Bool {
        lhs.id == rhs.id
    }
}
