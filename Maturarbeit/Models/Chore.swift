//
//  Chore.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import Foundation

struct Chore: Identifiable, Hashable {
    let id: UUID
    var title: String
    var assignedTo: UUID?
    var dueDate: Date?
    var isDone: Bool
    var recurrence: ChoreRecurrence
    var createdAt: Date
    var deadline: Date? // Deadline for one-time tasks (e.g., "complete within 1 week")
    
    init(
        id: UUID = UUID(),
        title: String,
        assignedTo: UUID? = nil,
        dueDate: Date? = nil,
        isDone: Bool = false,
        recurrence: ChoreRecurrence = .once,
        createdAt: Date = Date(),
        deadline: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.assignedTo = assignedTo
        self.dueDate = dueDate
        self.isDone = isDone
        self.recurrence = recurrence
        self.createdAt = createdAt
        self.deadline = deadline
    }
    
    // MARK: - Countdown Helpers
    
    /// Check if this task has a deadline
    var hasDeadline: Bool {
        deadline != nil
    }
    
    /// Get remaining time until deadline
    var timeRemaining: TimeInterval? {
        guard let deadline = deadline else { return nil }
        return deadline.timeIntervalSince(Date())
    }
    
    /// Check if deadline has passed
    var isOverdue: Bool {
        guard let remaining = timeRemaining else { return false }
        return remaining < 0
    }
    
    /// Format remaining time as human-readable string
    var deadlineCountdown: String {
        guard let remaining = timeRemaining else { return "" }
        
        if remaining < 0 {
            return "Überfällig"
        }
        
        let days = Int(remaining / 86400)
        let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if days > 0 {
            return "\(days) Tag\(days == 1 ? "" : "e") übrig"
        } else if hours > 0 {
            return "\(hours) Std. übrig"
        } else if minutes > 0 {
            return "\(minutes) Min. übrig"
        } else {
            return "Läuft ab!"
        }
    }
}
