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
    @State private var newChorePoints = 5
    @State private var selectedMemberID: UUID?
    
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
                    points: $newChorePoints,
                    selectedMemberID: $selectedMemberID,
                    members: appState.members
                ) {
                    Task {
                        await appState.addChore(
                            title: newChoreTitle,
                            points: newChorePoints,
                            assignedTo: selectedMemberID
                        )
                        resetForm()
                        showingAddChore = false
                    }
                }
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
                    ChoreRow(
                        chore: chore,
                        memberName: chore.assignedTo != nil ? appState.getMemberName(for: chore.assignedTo!) : nil,
                        onToggle: {
                            Task {
                                await appState.toggleChore(chore)
                            }
                        }
                    )
                    .contextMenu {
                        if appState.isCurrentUserParent {
                            Button(role: .destructive) {
                                Task {
                                    await appState.deleteChore(chore)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
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
        newChorePoints = 5
        selectedMemberID = nil
    }
}

// MARK: - Add Chore Sheet

struct AddChoreView_Refactored: View {
    @Binding var title: String
    @Binding var points: Int
    @Binding var selectedMemberID: UUID?
    let members: [FamilyMember]
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFieldIsFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Chore title", text: $title)
                        .focused($titleFieldIsFocused)
                        .accessibilityLabel("Chore title")
                        .accessibilityHint("Enter a name for the chore")
                    
                    HStack {
                        Text("Points")
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Spacer()
                        
                        Stepper("\(points)", value: $points, in: 1...20)
                            .accessibilityLabel("Points value: \(points)")
                            .accessibilityHint("Adjust the point value for this chore")
                    }
                } header: {
                    Text("Chore Details")
                }
                
                Section {
                    Picker("Assign to", selection: $selectedMemberID) {
                        Text("No assignment").tag(nil as UUID?)
                        ForEach(members) { member in
                            HStack {
                                Text(member.name)
                                Text("(\(member.role.displayLabel))")
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .tag(member.id as UUID?)
                        }
                    }
                    .accessibilityLabel("Assign chore to family member")
                } header: {
                    Text("Assignment")
                }
            }
            .navigationTitle("Add Chore")
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
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                titleFieldIsFocused = true
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

