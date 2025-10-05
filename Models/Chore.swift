//
//  Chore.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import Foundation

struct Chore: Identifiable {
    let id: UUID
    var title: String
    var points: Int
    var assignedTo: UUID?
    var dueDate: Date?
    var isDone: Bool
    
    init(id: UUID = UUID(), title: String, points: Int, assignedTo: UUID? = nil, dueDate: Date? = nil, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.points = points
        self.assignedTo = assignedTo
        self.dueDate = dueDate
        self.isDone = isDone
    }
}
