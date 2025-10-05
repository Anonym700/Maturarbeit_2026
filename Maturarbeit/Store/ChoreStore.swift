//
//  ChoreStore.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import Foundation

protocol ChoreStore {
    func loadChores() async -> [Chore]
    func saveChore(_ chore: Chore) async
    func updateChore(_ chore: Chore) async
    func deleteChore(_ chore: Chore) async
}
