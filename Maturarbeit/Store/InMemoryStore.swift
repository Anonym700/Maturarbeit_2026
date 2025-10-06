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
        
        // Pre-seed with 3 simple example tasks
        if chores.isEmpty {
            let now = Date()
            
            // Task 1: Created 2 days ago, deadline in 5 days (7 days total time)
            let task1Created = Calendar.current.date(byAdding: .day, value: -2, to: now)!
            let task1Deadline = Calendar.current.date(byAdding: .day, value: 5, to: now)!
            
            // Task 2: Created 1 day ago, deadline in 6 days (7 days total time)
            let task2Created = Calendar.current.date(byAdding: .day, value: -1, to: now)!
            let task2Deadline = Calendar.current.date(byAdding: .day, value: 6, to: now)!
            
            // Task 3: Just created, deadline in 7 days
            let task3Deadline = Calendar.current.date(byAdding: .day, value: 7, to: now)!
            
            chores = [
                Chore(title: "Zimmer aufräumen", assignedTo: defaultAssigneeID, dueDate: nil, isDone: false, recurrence: .once, createdAt: task1Created, deadline: task1Deadline),
                Chore(title: "Hausaufgaben machen", assignedTo: defaultAssigneeID, dueDate: nil, isDone: false, recurrence: .once, createdAt: task2Created, deadline: task2Deadline),
                Chore(title: "Müll rausbringen", assignedTo: defaultAssigneeID, dueDate: nil, isDone: false, recurrence: .once, createdAt: now, deadline: task3Deadline)
            ]
        }
    }
    
    /// Check if app version changed and reset data if needed
    private func checkAndResetIfNeeded() {
        let currentVersion = "2.2" // Updated: 3 simple countdown tasks
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
