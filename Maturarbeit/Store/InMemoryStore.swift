//
//  InMemoryStore.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import Foundation

class InMemoryStore: ChoreStore {
    private var chores: [Chore] = []
    
    init() {
        // Pre-seed with sample chores
        chores = [
            Chore(title: "Do the dishes", points: 5, assignedTo: nil, dueDate: nil, isDone: false),
            Chore(title: "Take out trash", points: 3, assignedTo: nil, dueDate: nil, isDone: false),
            Chore(title: "Clean your room", points: 8, assignedTo: nil, dueDate: nil, isDone: false)
        ]
    }
    
    func loadChores() async -> [Chore] {
        return chores
    }
    
    func saveChore(_ chore: Chore) async {
        chores.append(chore)
    }
    
    func updateChore(_ chore: Chore) async {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index] = chore
        }
    }
    
    func deleteChore(_ chore: Chore) async {
        chores.removeAll { $0.id == chore.id }
    }
}
