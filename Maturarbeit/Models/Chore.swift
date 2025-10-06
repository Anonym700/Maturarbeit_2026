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
    
    init(
        id: UUID = UUID(),
        title: String,
        assignedTo: UUID? = nil,
        dueDate: Date? = nil,
        isDone: Bool = false,
        recurrence: ChoreRecurrence = .once,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.assignedTo = assignedTo
        self.dueDate = dueDate
        self.isDone = isDone
        self.recurrence = recurrence
        self.createdAt = createdAt
    }
}
