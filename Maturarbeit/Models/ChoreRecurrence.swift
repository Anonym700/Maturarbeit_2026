//
//  ChoreRecurrence.swift
//  AemtliApp
//
//  Task recurrence/repeat options
//  Created: October 2025
//

import Foundation

enum ChoreRecurrence: String, Codable, CaseIterable, Identifiable {
    case once = "once"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .once:
            return "Einmalig"
        case .daily:
            return "Täglich"
        case .weekly:
            return "Wöchentlich"
        case .monthly:
            return "Monatlich"
        }
    }
    
    var icon: String {
        switch self {
        case .once:
            return "calendar"
        case .daily:
            return "calendar.circle"
        case .weekly:
            return "calendar.badge.clock"
        case .monthly:
            return "calendar.badge.plus"
        }
    }
    
    var description: String {
        switch self {
        case .once:
            return "Nur einmal ausführen"
        case .daily:
            return "Wird jeden Tag zurückgesetzt"
        case .weekly:
            return "Wird jede Woche zurückgesetzt"
        case .monthly:
            return "Wird jeden Monat zurückgesetzt"
        }
    }
}

