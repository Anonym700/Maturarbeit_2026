//
//  InMemoryStore.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import Foundation

class InMemoryStore: ChoreStore {
    private var chores: [Chore] = []
    private let defaultAssigneeID: UUID?
    
    init(defaultAssigneeID: UUID? = nil) {
        self.defaultAssigneeID = defaultAssigneeID
        
        // Check if we need to reset data (for fresh start)
        checkAndResetIfNeeded()
        
        // Pre-seed with sample chores with recurrence settings
        if chores.isEmpty {
            chores = [
                Chore(title: "Do the dishes", assignedTo: defaultAssigneeID, dueDate: nil, isDone: false, recurrence: .daily),
                Chore(title: "Take out trash", assignedTo: defaultAssigneeID, dueDate: nil, isDone: false, recurrence: .daily),
                Chore(title: "Clean your room", assignedTo: defaultAssigneeID, dueDate: nil, isDone: false, recurrence: .weekly)
            ]
        }
    }
    
    /// Check if app version changed and reset data if needed
    private func checkAndResetIfNeeded() {
        let currentVersion = "2.0" // Updated version with recurrence
        let savedVersion = UserDefaults.standard.string(forKey: "appDataVersion")
        
        if savedVersion != currentVersion {
            print("📱 App data version changed. Resetting to new format...")
            chores.removeAll()
            UserDefaults.standard.set(currentVersion, forKey: "appDataVersion")
            print("✅ Data reset complete!")
        }
    }
    
    func loadChores() async -> [Chore] {
        // Simulate small delay if needed, but data is already in memory
        print("📦 InMemoryStore: Loading \(chores.count) chores")
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
