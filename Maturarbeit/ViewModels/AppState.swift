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
    @Published var members: [FamilyMember] = []
    @Published var currentUserID: UUID?
    @Published var chores: [Chore] = []
    
    private let store: CloudKitStore
    private var midnightResetTimer: Timer?
    
    // Default members with FIXED UUIDs for consistency
    private var defaultMembers: [FamilyMember] {
        [
            FamilyMember(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                name: "Parent 1",
                role: .parent
            ),
            FamilyMember(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                name: "Anna",
                role: .child
            ),
            FamilyMember(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                name: "Max",
                role: .child
            )
        ]
    }
    
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
        // Initialize CloudKit Store
        self.store = CloudKitStore()
        
        Task { @MainActor in
            // Load FamilyMembers from CloudKit first
            await loadFamilyMembers()
            
            // If no members exist, create defaults and save to CloudKit
            if members.isEmpty {
                await setupDefaultFamilyMembers()
            }
            
            // Set current user to first parent, or first member
            self.currentUserID = members.first(where: { $0.role == .parent })?.id ?? members.first?.id
            
            // Then load chores and setup reset timer
            await loadChores()
            await checkAndResetIfNeeded()
            setupMidnightResetTimer()
        }
    }
    
    deinit {
        midnightResetTimer?.invalidate()
    }
    
    var currentUser: FamilyMember? {
        guard let currentUserID = currentUserID else { return nil }
        return members.first { $0.id == currentUserID }
    }
    
    var isCurrentUserParent: Bool {
        currentUser?.role == .parent
    }
    
    // MARK: - FamilyMember Management
    
    func loadFamilyMembers() async {
        members = await store.loadFamilyMembers()
        print("📱 Loaded \(members.count) family members from CloudKit")
    }
    
    func setupDefaultFamilyMembers() async {
        print("🏗️ Setting up default family members in CloudKit...")
        for member in defaultMembers {
            await store.saveFamilyMember(member)
        }
        await loadFamilyMembers()
    }
    
    func addFamilyMember(name: String, role: FamilyRole) async {
        let newMember = FamilyMember(name: name, role: role)
        members.append(newMember)
        await store.saveFamilyMember(newMember)
        
        // Verify save
        try? await Task.sleep(nanoseconds: 500_000_000)
        await loadFamilyMembers()
    }
    
    func deleteFamilyMember(_ member: FamilyMember) async {
        members.removeAll { $0.id == member.id }
        // Note: We'd need to add delete to CloudKitStore for this
        // For now, just remove from local array
        await loadFamilyMembers()
    }
    
    // MARK: - Chore Management
    
    func loadChores() async {
        chores = await store.loadChores()
    }
    
    func addChore(title: String, assignedTo: UUID?, recurrence: ChoreRecurrence, deadline: Date? = nil) async {
        let newChore = Chore(title: title, assignedTo: assignedTo, recurrence: recurrence, deadline: deadline)
        
        // Optimistic UI update - add to local list immediately
        chores.append(newChore)
        
        // Save to CloudKit and wait for completion
        await store.saveChore(newChore)
        
        // Verify save with retry logic
        await verifyAndRefresh(expectedID: newChore.id, maxRetries: 5)
    }
    
    func updateChore(_ chore: Chore) async {
        // Optimistic UI update - update in local list immediately
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index] = chore
        }
        
        // Save to CloudKit and wait for completion
        await store.updateChore(chore)
        
        // Verify save with retry logic
        await verifyAndRefresh(expectedID: chore.id, maxRetries: 5)
    }
    
    func toggleChore(_ chore: Chore) async {
        var updatedChore = chore
        updatedChore.isDone.toggle()
        
        // Optimistic UI update - toggle in local list immediately
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index] = updatedChore
        }
        
        // Save to CloudKit and wait for completion
        await store.updateChore(updatedChore)
        
        // Verify save with retry logic
        await verifyAndRefresh(expectedID: updatedChore.id, maxRetries: 5)
    }
    
    func deleteChore(_ chore: Chore) async {
        // Optimistic UI update - remove from local list immediately
        chores.removeAll { $0.id == chore.id }
        
        // Delete from CloudKit and wait for completion
        await store.deleteChore(chore)
        
        // No need to verify delete - just refresh after delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        await loadChores()
    }
    
    /// Verify that a chore exists in CloudKit before refreshing
    private func verifyAndRefresh(expectedID: UUID, maxRetries: Int) async {
        for attempt in 1...maxRetries {
            // Wait a bit before checking
            try? await Task.sleep(nanoseconds: 300_000_000 * UInt64(attempt)) // Progressive delay: 0.3s, 0.6s, 0.9s...
            
            let fetchedChores = await store.loadChores()
            if fetchedChores.contains(where: { $0.id == expectedID }) {
                // Found it! Refresh the UI
                chores = fetchedChores
                print("✅ Verified chore in CloudKit after \(attempt) attempts")
                return
            }
        }
        
        // If we couldn't verify, still do a final refresh
        print("⚠️ Could not verify chore in CloudKit, doing final refresh")
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
