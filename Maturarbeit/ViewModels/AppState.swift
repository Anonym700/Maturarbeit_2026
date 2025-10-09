//
//  AppState.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var members: [FamilyMember]
    @Published var currentUserID: UUID
    @Published var chores: [Chore] = []
    
    private let store: ChoreStore
    private var midnightResetTimer: Timer?
    
    // Default tasks that will be loaded each day after reset
    private var defaultTasks: [Chore] {
        // Get first child member for assignment, or first member if no child
        let defaultAssignee = members.first(where: { $0.role == .child })?.id ?? members.first?.id
        
        return [
            Chore(title: "Do the dishes", assignedTo: defaultAssignee, dueDate: nil, isDone: false, recurrence: .daily),
            Chore(title: "Take out trash", assignedTo: defaultAssignee, dueDate: nil, isDone: false, recurrence: .daily),
            Chore(title: "Clean your room", assignedTo: defaultAssignee, dueDate: nil, isDone: false, recurrence: .weekly)
        ]
    }
    
    init() {
        // Initialize with default members FIRST
        let parent = FamilyMember(name: "Parent 1", role: .parent)
        let child1 = FamilyMember(name: "Anna", role: .child)
        let child2 = FamilyMember(name: "Max", role: .child)
        
        self.members = [parent, child1, child2]
        self.currentUserID = parent.id
        
        // ✨ Switch to CloudKit Store
        self.store = CloudKitStore()
        
        Task { @MainActor in
            await loadChores()
            await checkAndResetIfNeeded()
            setupMidnightResetTimer()
        }
    }
    
    deinit {
        midnightResetTimer?.invalidate()
    }
    
    var currentUser: FamilyMember? {
        members.first { $0.id == currentUserID }
    }
    
    var isCurrentUserParent: Bool {
        currentUser?.role == .parent
    }
    
    func loadChores() async {
        chores = await store.loadChores()
    }
    
    func addChore(title: String, assignedTo: UUID?, recurrence: ChoreRecurrence, deadline: Date? = nil) async {
        let newChore = Chore(title: title, assignedTo: assignedTo, recurrence: recurrence, deadline: deadline)
        await store.saveChore(newChore)
        await loadChores()
    }
    
    func updateChore(_ chore: Chore) async {
        await store.updateChore(chore)
        await loadChores()
    }
    
    func toggleChore(_ chore: Chore) async {
        var updatedChore = chore
        updatedChore.isDone.toggle()
        await store.updateChore(updatedChore)
        await loadChores()
    }
    
    func deleteChore(_ chore: Chore) async {
        await store.deleteChore(chore)
        await loadChores()
    }
    
    func switchUser(to memberID: UUID) {
        currentUserID = memberID
    }
    
    func getMemberName(for id: UUID) -> String {
        members.first { $0.id == id }?.name ?? "Unknown"
    }
    
    // MARK: - Daily Reset Functions
    
    /// Manually reset all tasks (called from Settings)
    func resetDailyTasks() async {
        // Reset all existing tasks to not done
        for chore in chores {
            var updatedChore = chore
            updatedChore.isDone = false
            await store.updateChore(updatedChore)
        }
        
        // Reload chores
        await loadChores()
        
        // Save the last reset date
        UserDefaults.standard.set(Date(), forKey: "lastResetDate")
    }
    
    /// Check if we need to reset based on date change
    private func checkAndResetIfNeeded() async {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastReset = UserDefaults.standard.object(forKey: "lastResetDate") as? Date {
            // Check if last reset was on a different day
            if !calendar.isDate(lastReset, inSameDayAs: now) {
                await performAutomaticReset()
            }
        } else {
            // First time launch - set the reset date
            UserDefaults.standard.set(now, forKey: "lastResetDate")
        }
    }
    
    /// Perform automatic reset at midnight
    private func performAutomaticReset() async {
        print("🔄 Performing automatic daily reset...")
        
        // Delete all existing chores
        for chore in chores {
            await store.deleteChore(chore)
        }
        
        // Load default tasks
        for defaultTask in defaultTasks {
            await store.saveChore(defaultTask)
        }
        
        // Reload chores
        await loadChores()
        
        // Update last reset date
        UserDefaults.standard.set(Date(), forKey: "lastResetDate")
        
        print("✅ Daily reset complete!")
    }
    
    /// Setup a timer that fires at midnight
    private func setupMidnightResetTimer() {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate next midnight
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        components.day! += 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let nextMidnight = calendar.date(from: components) else { return }
        let timeInterval = nextMidnight.timeIntervalSince(now)
        
        print("⏰ Next automatic reset scheduled for: \(nextMidnight)")
        
        // Schedule timer for midnight
        DispatchQueue.main.async { [weak self] in
            self?.midnightResetTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.performAutomaticReset()
                    // Reschedule for next midnight
                    self?.setupMidnightResetTimer()
                }
            }
        }
    }
}
