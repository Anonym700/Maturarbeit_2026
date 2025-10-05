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
    @Published var currentUserID: UUID
    @Published var chores: [Chore] = []
    
    private let store: ChoreStore
    
    init() {
        self.store = InMemoryStore()
        
        // Initialize with default members
        let parent = FamilyMember(name: "Parent 1", role: .parent)
        let child = FamilyMember(name: "Child 1", role: .child)
        
        self.members = [parent, child]
        self.currentUserID = parent.id
        
        // Load initial chores
        Task {
            await loadChores()
        }
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
    
    func addChore(title: String, points: Int, assignedTo: UUID?) async {
        let newChore = Chore(title: title, points: points, assignedTo: assignedTo)
        await store.saveChore(newChore)
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
}
