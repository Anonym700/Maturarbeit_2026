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
    @Published var currentICloudUserID: String? // The logged-in iCloud user's record ID
    @Published var chores: [Chore] = []
    
    private let store: CloudKitStore
    private let cloudKitManager = CloudKitManager.shared
    private var midnightResetTimer: Timer?
    private var cloudKitNotificationObserver: NSObjectProtocol?
    
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
            // CRITICAL: Fetch iCloud user FIRST, then everything else
            await fetchCurrentICloudUser()
            
            // Only proceed if we have a valid iCloud user
            guard currentICloudUserID != nil else {
                print("❌ No iCloud user - cannot proceed with share detection")
                return
            }
            
            // CRITICAL: Check for existing family share with retry mechanism
            // This is essential for child devices on app restart
            await checkForSharedFamilyWithRetry(maxAttempts: 3)
            
            // If we have an active share, load participants
            if cloudKitManager.activeShare != nil {
                await loadShareParticipants()
            }
            
            // Determine current user based on share
            await determineCurrentUserFromShare()
            
            // Load chores and setup reset timer
            await loadChores()
            await checkAndResetIfNeeded()
            setupMidnightResetTimer()
        }
        
        // ✅ Listen for CloudKit changes (including share participant updates)
        // Store observer for cleanup
        cloudKitNotificationObserver = NotificationCenter.default.addObserver(
            forName: .cloudKitDataChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                print("🔄 CloudKit data changed, refreshing...")
                
                // Check if we still have an active share (with retry for reliability)
                await self.checkForSharedFamilyWithRetry(maxAttempts: 2)
                
                // If we have an active share, reload participants
                if self.cloudKitManager.activeShare != nil {
                    await self.loadShareParticipants()
                    await self.determineCurrentUserFromShare()
                }
                
                // Reload chores (this syncs tasks from other devices)
                await self.loadChores()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Create a deterministic UUID from a string (iCloud user ID)
    /// This ensures the same user ALWAYS gets the same UUID across app launches
    /// Uses a simple but deterministic hash based on character codes
    static func createDeterministicUUID(from string: String) -> UUID {
        // Create a deterministic hash from the string
        var hash: UInt64 = 5381 // DJB2 hash initial value
        
        for char in string.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(char) // hash * 33 + char
        }
        
        // Add a namespace to avoid collisions
        let namespace = "com.christosalexisfantino.familymember"
        for char in namespace.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(char)
        }
        
        // Create UUID v5-like string from hash (deterministic)
        // Format: xxxxxxxx-xxxx-5xxx-yxxx-xxxxxxxxxxxx
        let part1 = UInt32(hash & 0xFFFFFFFF)
        let part2 = UInt16((hash >> 32) & 0xFFFF)
        let part3 = UInt16(((hash >> 48) & 0x0FFF) | 0x5000) // Version 5
        let part4 = UInt16(((hash >> 60) & 0x3FFF) | 0x8000) // Variant RFC4122
        
        // Use a second hash for the last part
        var hash2: UInt64 = hash
        for char in string.utf8.reversed() {
            hash2 = ((hash2 << 5) &+ hash2) &+ UInt64(char)
        }
        let part5 = UInt64(hash2 & 0xFFFFFFFFFFFF) // 48 bits
        
        let uuidString = String(format: "%08x-%04x-%04x-%04x-%012llx",
                               part1, part2, part3, part4, part5)
        
        return UUID(uuidString: uuidString) ?? UUID()
    }
    
    // MARK: - Share Management with Retry
    
    /// Check for shared family with retry mechanism
    /// This is critical for child devices where the share might not be immediately available on app restart
    private func checkForSharedFamilyWithRetry(maxAttempts: Int) async {
        for attempt in 1...maxAttempts {
            print("🔄 Share check attempt \(attempt)/\(maxAttempts)...")
            
            do {
                try await cloudKitManager.checkForSharedFamily()
                
                // If we found a share, we're done!
                if cloudKitManager.activeShare != nil {
                    print("✅ Share found on attempt \(attempt)")
                    return
                }
            } catch {
                print("⚠️ Share check attempt \(attempt) failed: \(error)")
            }
            
            // If not the last attempt, wait before retrying
            if attempt < maxAttempts {
                let delay = Double(attempt) * 1.0 // Progressive delay: 1s, 2s, 3s
                print("   Retrying in \(delay)s...")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        if cloudKitManager.activeShare == nil {
            print("⚠️ No share found after \(maxAttempts) attempts")
        }
    }
    
    // MARK: - iCloud User Management
    
    /// Fetch the current iCloud user's record ID
    private func fetchCurrentICloudUser() async {
        do {
            let recordID = try await cloudKitManager.fetchCurrentUserRecordID()
            self.currentICloudUserID = recordID.recordName
            print("👤 iCloud User detected: \(recordID.recordName)")
        } catch {
            print("❌ Failed to fetch iCloud user: \(error)")
        }
    }
    
    /// Determine the current user based on share ownership
    func determineCurrentUserFromShare() async {
        guard let iCloudUserID = currentICloudUserID else {
            print("⚠️ No iCloud user found")
            return
        }
        
        print("🔍 Determining current user from share (iCloud ID: \(iCloudUserID))...")
        
        // IMPORTANT: Use deterministic UUID for consistent user identification
        let determinicUserID = Self.createDeterministicUUID(from: iCloudUserID)
        print("   Generated deterministic UUID: \(determinicUserID)")
        
        // Check if user is already in members list (loaded from share participants)
        if let existingMember = members.first(where: { $0.iCloudUserID == iCloudUserID }) {
            self.currentUserID = existingMember.id
            print("✅ Found existing member: \(existingMember.name) (ID: \(existingMember.id), Role: \(existingMember.role.displayLabel))")
            return
        }
        
        // Get user info from share participants
        let participants = await cloudKitManager.getShareParticipants()
        
        if let participant = participants.first(where: { $0.userIdentity.userRecordID?.recordName == iCloudUserID }) {
            // CRITICAL FIX: Determine role from participant correctly
            // The participant.role == .owner means they are the share owner (Parent)
            // All other participants are children
            let isOwner = participant.role == .owner
            let role: FamilyRole = isOwner ? .parent : .child
            
            let name = participant.userIdentity.nameComponents?.formatted() ?? "You"
            
            let member = FamilyMember(
                id: determinicUserID, // Use deterministic UUID
                name: name,
                role: role,
                iCloudUserID: iCloudUserID
            )
            
            // Update members list if not already present
            if !members.contains(where: { $0.iCloudUserID == iCloudUserID }) {
                members.append(member)
                print("   Added new member to list")
            }
            
            self.currentUserID = member.id
            print("✅ User from share: \(name) (\(role.displayLabel)) [UUID: \(member.id), isOwner: \(isOwner)]")
        } else if cloudKitManager.activeShare != nil {
            // User is in a share but not in participants list yet - create member
            // Use cloudKitManager.userRole as fallback
            let role = cloudKitManager.userRole
            let member = FamilyMember(
                id: determinicUserID, // Use deterministic UUID
                name: "You",
                role: role,
                iCloudUserID: iCloudUserID
            )
            
            members.append(member)
            self.currentUserID = member.id
            print("✅ Created user from share: \(role.displayLabel) [UUID: \(member.id)]")
        } else {
            print("ℹ️ No active share - user needs to create or join family")
        }
    }
    
    deinit {
        midnightResetTimer?.invalidate()
        
        // CRITICAL: Remove notification observer to prevent memory leaks
        if let observer = cloudKitNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    var currentUser: FamilyMember? {
        guard let currentUserID = currentUserID else { return nil }
        return members.first { $0.id == currentUserID }
    }
    
    var isCurrentUserParent: Bool {
        currentUser?.role == .parent
    }
    
    var hasActiveShare: Bool {
        cloudKitManager.activeShare != nil
    }
    
    var isShareOwner: Bool {
        cloudKitManager.isShareOwner
    }
    
    // MARK: - Family Sharing
    
    /// Delete existing share and create a fresh one (for fixing broken shares)
    func resetFamilyShare() async throws -> URL {
        try await cloudKitManager.deleteExistingShare()
        // Force creation of a brand new share and link
        let url = try await cloudKitManager.getFamilyShareURL(forceNew: true)
        print("✅ Family share reset and URL created: \(url)")
        return url
    }
    
    /// Create family share and get URL (Parent only)
    func createFamilyShare() async throws -> URL {
        let url = try await cloudKitManager.getFamilyShareURL()
        print("✅ Family share URL created: \(url)")
        return url
    }
    
    /// Load all share participants as family members
    /// This REPLACES the members list with participants from the active share
    func loadShareParticipants() async {
        // CRITICAL: Clear existing members first to prevent duplicates
        self.members = []
        
        let participants = await cloudKitManager.getShareParticipants()
        
        // Only process if we have participants
        guard !participants.isEmpty else {
            return
        }
        
        var newMembers: [FamilyMember] = []
        
        for participant in participants {
            guard let userID = participant.userIdentity.userRecordID?.recordName else { 
                continue
            }
            
            // Check if this is the current user
            let isCurrentUser = (userID == currentICloudUserID)
            
            // Try to get name from CloudKit identity
            var name: String? = nil
            
            // Method 1: Try formatted name components
            if let nameComponents = participant.userIdentity.nameComponents {
                let formatted = nameComponents.formatted()
                if !formatted.isEmpty && formatted != " " {
                    name = formatted
                }
            }
            
            // Method 2: Try individual name components
            if name == nil || name?.isEmpty == true {
                if let nameComponents = participant.userIdentity.nameComponents {
                    if let givenName = nameComponents.givenName, let familyName = nameComponents.familyName {
                        name = "\(givenName) \(familyName)"
                    } else if let givenName = nameComponents.givenName {
                        name = givenName
                    } else if let familyName = nameComponents.familyName {
                        name = familyName
                    }
                }
            }
            
            // Method 3: Try lookupInfo (email or phone)
            if name == nil || name?.isEmpty == true {
                if let lookupInfo = participant.userIdentity.lookupInfo {
                    if let email = lookupInfo.emailAddress {
                        let emailName = email.components(separatedBy: "@").first ?? email
                        name = emailName
                    } else if let phone = lookupInfo.phoneNumber {
                        name = phone
                    }
                }
            }
            
            // Method 4: Check if it's the current user
            if name == nil || name?.isEmpty == true {
                if isCurrentUser {
                    name = "You"
                }
            }
            
            // Fallback: Use role-based name
            if name == nil || name?.isEmpty == true {
                let isOwner = participant.role == .owner
                if isCurrentUser {
                    name = isOwner ? "You (Parent)" : "You (Child)"
                } else {
                    name = isOwner ? "Parent" : "Family Member"
                }
            }
            
            // Determine role correctly
            let isOwner = participant.role == .owner
            let role: FamilyRole = isOwner ? .parent : .child
            
            // Create deterministic UUID from iCloud user ID
            let memberID = Self.createDeterministicUUID(from: userID)
            
            let member = FamilyMember(
                id: memberID,
                name: name ?? "Family Member",
                role: role,
                iCloudUserID: userID
            )
            
            newMembers.append(member)
        }
        
        // Replace members list with participants from share
        self.members = newMembers
        
        // Set currentUserID after loading participants
        if let iCloudUserID = currentICloudUserID {
            if let currentMember = members.first(where: { $0.iCloudUserID == iCloudUserID }) {
                self.currentUserID = currentMember.id
            }
        }
    }
    
    // MARK: - Permission System
    
    /// Check if current user is registered and linked to an iCloud account
    var isUserRegistered: Bool {
        currentUserID != nil && currentUser != nil
    }
    
    /// Check if current user can create chores
    var canCreateChores: Bool {
        isCurrentUserParent
    }
    
    /// Check if current user can edit chores
    var canEditChores: Bool {
        isCurrentUserParent
    }
    
    /// Check if current user can delete chores
    var canDeleteChores: Bool {
        isCurrentUserParent
    }
    
    /// Check if current user can manage family members
    var canManageFamilyMembers: Bool {
        isCurrentUserParent
    }
    
    /// Check if current user can complete assigned chores
    func canCompleteChore(_ chore: Chore) -> Bool {
        // Parents can complete any chore
        if isCurrentUserParent {
            return true
        }
        // Children can only complete chores assigned to them
        return chore.assignedTo == currentUserID
    }
    
    // MARK: - FamilyMember Management
    
    func loadFamilyMembers() async {
        // Only load from CloudKit if we don't have an active share
        // If we have a share, we should only use participants from the share
        if cloudKitManager.activeShare == nil {
            members = await store.loadFamilyMembers()
        }
        // If we have a share, members are loaded via loadShareParticipants()
    }
    
    func setupDefaultFamilyMembers() async {
        print("🏗️ Setting up default family members in CloudKit...")
        for member in defaultMembers {
            await store.saveFamilyMember(member)
        }
        await loadFamilyMembers()
    }
    
    func addFamilyMember(name: String, role: FamilyRole, linkToCurrentUser: Bool = false) async {
        let iCloudUserID = linkToCurrentUser ? currentICloudUserID : nil
        
        // If linking to current user, use deterministic UUID
        let memberID: UUID
        if linkToCurrentUser, let iCloudUserID = iCloudUserID {
            memberID = Self.createDeterministicUUID(from: iCloudUserID)
            print("   Creating member with deterministic UUID: \(memberID)")
        } else {
            memberID = UUID()
        }
        
        let newMember = FamilyMember(id: memberID, name: name, role: role, iCloudUserID: iCloudUserID)
        members.append(newMember)
        await store.saveFamilyMember(newMember)
        
        // Verify save
        try? await Task.sleep(nanoseconds: 500_000_000)
        await loadFamilyMembers()
        
        // If linking to current user, update currentUserID
        if linkToCurrentUser {
            await determineCurrentUserFromShare()
        }
    }
    
    /// Link current iCloud user to an existing family member
    func linkCurrentUserToMember(_ member: FamilyMember) async {
        guard let iCloudUserID = currentICloudUserID else {
            print("❌ No iCloud user ID available")
            return
        }
        
        // Use deterministic UUID for consistent identification
        let deterministicID = Self.createDeterministicUUID(from: iCloudUserID)
        
        // Create updated member with iCloud ID and deterministic UUID
        let updatedMember = FamilyMember(
            id: deterministicID, // Use deterministic UUID
            name: member.name,
            role: member.role,
            iCloudUserID: iCloudUserID
        )
        
        // Remove old member and add updated one
        members.removeAll { $0.id == member.id }
        members.append(updatedMember)
        
        // Save to CloudKit
        await store.saveFamilyMember(updatedMember)
        
        // Verify save and update current user
        try? await Task.sleep(nanoseconds: 500_000_000)
        await loadFamilyMembers()
        await determineCurrentUserFromShare()
        
        print("✅ Linked iCloud user to \(member.name) with UUID: \(deterministicID)")
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
    
    func getMemberName(for id: UUID) -> String {
        members.first { $0.id == id }?.name ?? "Unknown"
    }
    
    /// Manually reload all data from CloudKit (for refresh button)
    func reloadAllData() async {
        print("🔄 Manual reload triggered...")
        
        // Check for shared family (with retry for reliability)
        await checkForSharedFamilyWithRetry(maxAttempts: 2)
        
        // If we have an active share, reload participants
        if cloudKitManager.activeShare != nil {
            await loadShareParticipants()
            await determineCurrentUserFromShare()
        }
        
        // Reload chores (this syncs tasks from other devices)
        await loadChores()
        
        print("✅ Manual reload complete!")
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
