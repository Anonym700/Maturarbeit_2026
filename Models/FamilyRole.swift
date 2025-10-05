//
//  FamilyRole.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import Foundation

enum FamilyRole: String, CaseIterable, Identifiable {
    case parent = "parent"
    case child = "child"
    
    var id: String { rawValue }
    
    var displayLabel: String {
        switch self {
        case .parent:
            return "Parent"
        case .child:
            return "Child"
        }
    }
}
