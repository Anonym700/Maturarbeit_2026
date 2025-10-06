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
    @State private var editingChore: Chore?
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Main content
                Group {
                    if appState.chores.isEmpty {
                        emptyStateView
                    } else {
                        choresList
                    }
                }
                
                // Floating Action Button (Parents only)
                if appState.isCurrentUserParent {
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
                    members: appState.members
                ) {
                    Task {
                        await appState.addChore(
                            title: newChoreTitle,
                            assignedTo: selectedMemberID,
                            recurrence: selectedRecurrence
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
                ForEach(appState.chores) { chore in
                    ChoreRowWithActions(
                        chore: chore,
                        memberName: chore.assignedTo != nil ? appState.getMemberName(for: chore.assignedTo!) : nil,
                        isParent: appState.isCurrentUserParent,
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
    
    // MARK: - Helper Methods
    
    private func resetForm() {
        newChoreTitle = ""
        selectedMemberID = nil
        selectedRecurrence = .daily
    }
}

// MARK: - Chore Row With Actions

struct ChoreRowWithActions: View {
    let chore: Chore
    let memberName: String?
    let isParent: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: chore.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(chore.isDone ? AppTheme.Colors.success : AppTheme.Colors.accent)
                    .frame(width: AppTheme.Layout.minTapTarget, height: AppTheme.Layout.minTapTarget)
            }
            .accessibilityLabel(chore.isDone ? "Completed" : "Not completed")
            .accessibilityHint("Double-tap to toggle completion")
            
            // Task Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(chore.title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.text)
                    .strikethrough(chore.isDone, color: AppTheme.Colors.textSecondary)
                
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    // Recurrence Badge
                    if chore.recurrence != .once {
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
                        if chore.recurrence != .once {
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
            
            // Action Buttons (Parents only)
            if isParent {
                HStack(spacing: AppTheme.Spacing.xxSmall) {
                    // Edit Button
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.body)
                            .foregroundColor(AppTheme.Colors.accent)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.Colors.accent.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Edit task")
                    
                    // Delete Button
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
    let members: [FamilyMember]
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFieldIsFocused: Bool
    
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

