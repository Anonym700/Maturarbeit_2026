//
//  ChoresView.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import SwiftUI

struct ChoresView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddChore = false
    @State private var newChoreTitle = ""
    @State private var selectedMemberID: UUID?
    @State private var deadline: Date?
    
    var body: some View {
        NavigationView {
            VStack {
                if !appState.isUserRegistered {
                    // Show registration prompt
                    registrationPromptView
                } else {
                    // Show chores list
                    List {
                        ForEach(appState.chores) { chore in
                            ChoreRowView(chore: chore)
                        }
                        .onDelete(perform: appState.canDeleteChores ? deleteChores : nil)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.black)
                    
                    if appState.canCreateChores {
                        Button(action: { showingAddChore = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.purple)
                                .clipShape(Circle())
                        }
                        .padding(.bottom)
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Chores")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let currentUser = appState.currentUser {
                        Text(currentUser.role.displayLabel)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .sheet(isPresented: $showingAddChore) {
                AddChoreView(
                    title: $newChoreTitle,
                    selectedMemberID: $selectedMemberID,
                    deadline: $deadline,
                    members: appState.members
                ) {
                    Task {
                        await appState.addChore(
                            title: newChoreTitle,
                            assignedTo: selectedMemberID,
                            recurrence: .daily,
                            deadline: deadline
                        )
                        newChoreTitle = ""
                        selectedMemberID = nil
                        deadline = nil
                        showingAddChore = false
                    }
                }
            }
        }
    }
    
    // MARK: - Registration Prompt
    
    private var registrationPromptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("Account Not Linked")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Please link your iCloud account to a family member in the Family tab to continue.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deleteChores(offsets: IndexSet) {
        for index in offsets {
            let chore = appState.chores[index]
            Task {
                await appState.deleteChore(chore)
            }
        }
    }
}

struct ChoreRowView: View {
    @EnvironmentObject var appState: AppState
    let chore: Chore
    
    var canToggle: Bool {
        appState.canCompleteChore(chore)
    }
    
    var body: some View {
        HStack {
            Button(action: {
                guard canToggle else { return }
                Task {
                    await appState.toggleChore(chore)
                }
            }) {
                Image(systemName: chore.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(chore.isDone ? .green : .purple)
                    .font(.title2)
            }
            .disabled(!canToggle)
            .opacity(canToggle ? 1.0 : 0.5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .strikethrough(chore.isDone)
                
                HStack(spacing: 8) {
                    if let assignedTo = chore.assignedTo {
                        Text(appState.getMemberName(for: assignedTo))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Show deadline countdown if present
                    if chore.hasDeadline {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(chore.deadlineCountdown)
                                .font(.caption)
                        }
                        .foregroundColor(chore.isOverdue ? .red : .orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(chore.isOverdue ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                        .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .listRowBackground(Color(red: 32/255, green: 32/255, blue: 36/255))
    }
}

struct AddChoreView: View {
    @Binding var title: String
    @Binding var selectedMemberID: UUID?
    @Binding var deadline: Date?
    @State private var hasDeadline = false
    @State private var deadlineDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 1 week from now
    let members: [FamilyMember]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Chore Details") {
                    TextField("Chore title", text: $title)
                }
                
                Section("Assignment") {
                    Picker("Assign to", selection: $selectedMemberID) {
                        Text("No assignment").tag(nil as UUID?)
                        ForEach(members) { member in
                            Text(member.name).tag(member.id as UUID?)
                        }
                    }
                }
                
                Section("Deadline (Countdown)") {
                    Toggle("Deadline festlegen", isOn: $hasDeadline)
                        .tint(.purple)
                    
                    if hasDeadline {
                        DatePicker("Frist bis", 
                                 selection: $deadlineDate,
                                 in: Date()...,
                                 displayedComponents: [.date, .hourAndMinute])
                        
                        Text("Die Aufgabe muss bis zu diesem Zeitpunkt erledigt werden")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
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
                        deadline = hasDeadline ? deadlineDate : nil
                        onSave()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ChoresView()
        .environmentObject(AppState())
}
