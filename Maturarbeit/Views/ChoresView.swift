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
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(appState.chores) { chore in
                        ChoreRowView(chore: chore)
                    }
                    .onDelete(perform: appState.isCurrentUserParent ? deleteChores : nil)
                }
                .listStyle(PlainListStyle())
                .background(Color.black)
                
                if appState.isCurrentUserParent {
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
                    members: appState.members
                ) {
                    Task {
                        await appState.addChore(
                            title: newChoreTitle,
                            assignedTo: selectedMemberID,
                            recurrence: .daily
                        )
                        newChoreTitle = ""
                        selectedMemberID = nil
                        showingAddChore = false
                    }
                }
            }
        }
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
    
    var body: some View {
        HStack {
            Button(action: {
                Task {
                    await appState.toggleChore(chore)
                }
            }) {
                Image(systemName: chore.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(chore.isDone ? .green : .purple)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .strikethrough(chore.isDone)
                
                if let assignedTo = chore.assignedTo {
                    Text(appState.getMemberName(for: assignedTo))
                        .font(.caption)
                        .foregroundColor(.gray)
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
                }
            }
        }
    }
}

#Preview {
    ChoresView()
        .environmentObject(AppState())
}
