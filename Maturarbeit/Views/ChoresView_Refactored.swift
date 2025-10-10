//
//  ChoresView_Refactored.swift
//  AemtliApp
//
//  Refactored version with improved UI/UX, accessibility, and design system
//  Updated: October 2025
//

import SwiftUI

struct ChoresView_Refactored: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddChore = false
    @State private var newChoreTitle = ""
    @State private var selectedMemberID: UUID?
    @State private var selectedRecurrence: ChoreRecurrence = .daily
    @State private var deadline: Date?
    @State private var editingChore: Chore?
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Main content
                Group {
                    if !appState.isUserRegistered {
                        // Show registration prompt
                        registrationPromptView
                    } else if filteredChores.isEmpty {
                        emptyStateView
                    } else {
                        choresList
                    }
                }
                
                // Floating Action Button (Parents only, and only if registered)
                if appState.isUserRegistered && appState.canCreateChores {
                    FloatingActionButton(
                        icon: "plus",
                        accessibilityLabel: "Add new chore"
                    ) {
                        showingAddChore = true
                    }
                    .padding(.bottom, AppTheme.Spacing.medium)
                }
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Chores")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let currentUser = appState.currentUser {
                        RoleBadge(role: currentUser.role.displayLabel)
                    }
                }
            }
            .sheet(isPresented: $showingAddChore) {
                AddChoreView_Refactored(
                    title: $newChoreTitle,
                    selectedMemberID: $selectedMemberID,
                    selectedRecurrence: $selectedRecurrence,
                    deadline: $deadline,
                    members: appState.members
                ) {
                    Task {
                        await appState.addChore(
                            title: newChoreTitle,
                            assignedTo: selectedMemberID,
                            recurrence: selectedRecurrence,
                            deadline: deadline
                        )
                        resetForm()
                        showingAddChore = false
                    }
                }
            }
            .sheet(item: $editingChore) { chore in
                EditChoreView(
                    chore: chore,
                    members: appState.members
                ) { updatedChore in
                    Task {
                        await appState.updateChore(updatedChore)
                        editingChore = nil
                    }
                }
                .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Registration Prompt
    
    private var registrationPromptView: some View {
        EmptyStateView(
            icon: "person.crop.circle.badge.exclamationmark",
            title: "Account Not Linked",
            message: "Please link your iCloud account to a family member in the Family tab to continue.",
            actionTitle: nil,
            action: nil
        )
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "tray",
            title: appState.isCurrentUserParent ? "No Chores Yet" : "No Tasks Assigned",
            message: appState.isCurrentUserParent
                ? "Get started by creating your first chore. Tap the + button below."
                : "Check back later for new tasks from your parents.",
            actionTitle: appState.isCurrentUserParent ? "Add First Chore" : nil,
            action: appState.isCurrentUserParent ? { showingAddChore = true } : nil
        )
    }
    
    // MARK: - Chores List
    
    private var choresList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(filteredChores) { chore in
                    ChoreRowWithActions(
                        chore: chore,
                        memberName: chore.assignedTo != nil ? appState.getMemberName(for: chore.assignedTo!) : nil,
                        canToggle: appState.canCompleteChore(chore),
                        canEdit: appState.canEditChores,
                        canDelete: appState.canDeleteChores,
                        onToggle: {
                            Task {
                                await appState.toggleChore(chore)
                            }
                        },
                        onEdit: {
                            editingChore = chore
                        },
                        onDelete: {
                            Task {
                                await appState.deleteChore(chore)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.top, AppTheme.Spacing.small)
            .padding(.bottom, AppTheme.Spacing.xxxLarge + AppTheme.Spacing.medium) // Space for FAB
        }
    }
    
    // MARK: - Filtered Chores
    
    /// Filter chores: Children only see their own tasks, Parents see all
    private var filteredChores: [Chore] {
        if appState.isCurrentUserParent {
            return appState.chores
        } else {
            // Children only see tasks assigned to them
            return appState.chores.filter { $0.assignedTo == appState.currentUserID }
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetForm() {
        newChoreTitle = ""
        selectedMemberID = nil
        selectedRecurrence = .daily
        deadline = nil
    }
}

// MARK: - Chore Row With Actions

struct ChoreRowWithActions: View {
    let chore: Chore
    let memberName: String?
    let canToggle: Bool
    let canEdit: Bool
    let canDelete: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            // Checkbox
            Button(action: {
                guard canToggle else { return }
                onToggle()
            }) {
                Image(systemName: chore.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(chore.isDone ? AppTheme.Colors.success : AppTheme.Colors.accent)
                    .frame(width: AppTheme.Layout.minTapTarget, height: AppTheme.Layout.minTapTarget)
            }
            .disabled(!canToggle)
            .opacity(canToggle ? 1.0 : 0.5)
            .accessibilityLabel(chore.isDone ? "Completed" : "Not completed")
            .accessibilityHint(canToggle ? "Double-tap to toggle completion" : "You cannot toggle this task")
            
            // Task Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(chore.title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.text)
                    .strikethrough(chore.isDone, color: AppTheme.Colors.textSecondary)
                
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    // Countdown Badge (if deadline exists)
                    if chore.hasDeadline {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(chore.deadlineCountdown)
                                .font(AppTheme.Typography.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(chore.isOverdue ? AppTheme.Colors.error : AppTheme.Colors.warning)
                        .cornerRadius(6)
                    }
                    
                    // Recurrence Badge
                    if chore.recurrence != .once && !chore.hasDeadline {
                        HStack(spacing: 2) {
                            Image(systemName: chore.recurrence.icon)
                                .font(.caption2)
                            Text(chore.recurrence.displayName)
                                .font(AppTheme.Typography.caption)
                        }
                        .foregroundColor(AppTheme.Colors.accent)
                    }
                    
                    // Member assignment
                    if let memberName = memberName {
                        if chore.recurrence != .once || chore.hasDeadline {
                            Text("•")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        Text(memberName)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons (Only if user has permissions)
            if canEdit || canDelete {
                HStack(spacing: AppTheme.Spacing.xxSmall) {
                    // Edit Button
                    if canEdit {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.body)
                                .foregroundColor(AppTheme.Colors.accent)
                                .frame(width: 32, height: 32)
                                .background(AppTheme.Colors.accent.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Edit task")
                    }
                    
                    // Delete Button
                    if canDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.body)
                                .foregroundColor(AppTheme.Colors.error)
                                .frame(width: 32, height: 32)
                                .background(AppTheme.Colors.error.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Delete task")
                    }
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Add Chore Sheet

struct AddChoreView_Refactored: View {
    @Binding var title: String
    @Binding var selectedMemberID: UUID?
    @Binding var selectedRecurrence: ChoreRecurrence
    @Binding var deadline: Date?
    let members: [FamilyMember]
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFieldIsFocused: Bool
    @State private var hasDeadline = false
    @State private var deadlineDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 1 week from now
    
    // Validation: Check if all required fields are filled
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && selectedMemberID != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Task title", text: $title)
                        .focused($titleFieldIsFocused)
                        .accessibilityLabel("Task title")
                        .accessibilityHint("Enter a name for the task")
                } header: {
                    Text("Task Details")
                } footer: {
                    if title.trimmingCharacters(in: .whitespaces).isEmpty && !title.isEmpty {
                        Text("Title cannot be empty")
                            .foregroundColor(AppTheme.Colors.error)
                            .font(AppTheme.Typography.caption)
                    }
                }
                
                Section {
                    Picker("Wiederholung", selection: $selectedRecurrence) {
                        ForEach(ChoreRecurrence.allCases) { recurrence in
                            HStack {
                                Image(systemName: recurrence.icon)
                                Text(recurrence.displayName)
                            }
                            .tag(recurrence)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(selectedRecurrence.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } header: {
                    Text("Frequency")
                }
                
                Section {
                    Toggle("Deadline festlegen", isOn: $hasDeadline)
                        .tint(AppTheme.Colors.accent)
                    
                    if hasDeadline {
                        DatePicker("Frist bis", 
                                 selection: $deadlineDate,
                                 in: Date()...,
                                 displayedComponents: [.date, .hourAndMinute])
                    }
                } header: {
                    Text("Deadline (Countdown)")
                } footer: {
                    if hasDeadline {
                        Text("Die Aufgabe muss bis zu diesem Zeitpunkt erledigt werden")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Section {
                    Picker("Assign to", selection: $selectedMemberID) {
                        Text("Select a member").tag(nil as UUID?)
                        ForEach(members) { member in
                            HStack {
                                Text(member.name)
                                Text("(\(member.role.displayLabel))")
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .tag(member.id as UUID?)
                        }
                    }
                    .accessibilityLabel("Assign task to family member")
                } header: {
                    Text("Assignment")
                } footer: {
                    if selectedMemberID == nil {
                        HStack(spacing: AppTheme.Spacing.xxSmall) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                            Text("Please assign this task to a family member")
                        }
                        .foregroundColor(AppTheme.Colors.warning)
                        .font(AppTheme.Typography.caption)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Set deadline based on toggle
                        deadline = hasDeadline ? deadlineDate : nil
                        onSave()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                titleFieldIsFocused = true
            }
        }
    }
}

// MARK: - Edit Chore View

struct EditChoreView: View {
    let chore: Chore
    let members: [FamilyMember]
    let onSave: (Chore) -> Void
    
    @State private var title: String
    @State private var selectedMemberID: UUID?
    @State private var selectedRecurrence: ChoreRecurrence
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFieldIsFocused: Bool
    
    init(chore: Chore, members: [FamilyMember], onSave: @escaping (Chore) -> Void) {
        self.chore = chore
        self.members = members
        self.onSave = onSave
        
        // Pre-validate that we have members
        guard !members.isEmpty else {
            print("⚠️ EditChoreView: No members available!")
            _title = State(initialValue: "")
            _selectedMemberID = State(initialValue: nil)
            _selectedRecurrence = State(initialValue: .daily)
            return
        }
        
        _title = State(initialValue: chore.title)
        // Ensure we have a valid selectedMemberID - use first member if chore has none
        let assigneeID = chore.assignedTo ?? members.first?.id
        _selectedMemberID = State(initialValue: assigneeID)
        _selectedRecurrence = State(initialValue: chore.recurrence)
        
        // Debug info
        print("📝 EditChoreView init:")
        print("   Title: \(chore.title)")
        print("   AssignedTo: \(String(describing: chore.assignedTo))")
        print("   Recurrence: \(chore.recurrence.displayName)")
        print("   Members count: \(members.count)")
        print("   Selected Member: \(String(describing: assigneeID))")
    }
    
    // Validation: Check if all required fields are filled
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && selectedMemberID != nil
    }
    
    var body: some View {
        NavigationView {
            editForm
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedChore = chore
                        updatedChore.title = title.trimmingCharacters(in: .whitespaces)
                        updatedChore.assignedTo = selectedMemberID
                        updatedChore.recurrence = selectedRecurrence
                        onSave(updatedChore)
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var editForm: some View {
        Form {
            Section {
                TextField("Task title", text: $title)
                    .focused($titleFieldIsFocused)
                    .accessibilityLabel("Task title")
            } header: {
                Text("Task Details")
            } footer: {
                if title.trimmingCharacters(in: .whitespaces).isEmpty && !title.isEmpty {
                    Text("Title cannot be empty")
                        .foregroundColor(AppTheme.Colors.error)
                        .font(AppTheme.Typography.caption)
                }
            }
                
                Section {
                    Picker("Wiederholung", selection: $selectedRecurrence) {
                        ForEach(ChoreRecurrence.allCases) { recurrence in
                            HStack {
                                Image(systemName: recurrence.icon)
                                Text(recurrence.displayName)
                            }
                            .tag(recurrence)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(selectedRecurrence.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } header: {
                    Text("Frequency")
                }
                
            Section {
                Picker("Assign to", selection: $selectedMemberID) {
                    Text("Select a member").tag(nil as UUID?)
                    ForEach(members) { member in
                        HStack {
                            Text(member.name)
                            Text("(\(member.role.displayLabel))")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .tag(member.id as UUID?)
                    }
                }
            } header: {
                Text("Assignment")
            } footer: {
                if selectedMemberID == nil {
                    HStack(spacing: AppTheme.Spacing.xxSmall) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text("Please assign this task to a family member")
                    }
                    .foregroundColor(AppTheme.Colors.warning)
                    .font(AppTheme.Typography.caption)
                }
            }
        }
        }
    }


// MARK: - Preview

#Preview {
    ChoresView_Refactored()
        .environmentObject(AppState())
}

#Preview("Empty State") {
    let appState = AppState()
    appState.chores = []
    return ChoresView_Refactored()
        .environmentObject(appState)
}

