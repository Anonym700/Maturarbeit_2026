//
//  FamilyView.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import SwiftUI

struct FamilyView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Current User")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Picker("Select User", selection: $appState.currentUserID) {
                        ForEach(appState.members) { member in
                            HStack {
                                Text(member.name)
                                Text("(\(member.role.displayLabel))")
                                    .foregroundColor(.gray)
                            }
                            .tag(member.id)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(red: 32/255, green: 32/255, blue: 36/255))
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Family Members")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(appState.members) { member in
                        HStack {
                            Image(systemName: member.role == .parent ? "person.crop.circle" : "person.crop.circle.fill")
                                .foregroundColor(.purple)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.name)
                                    .font(.body)
                                    .foregroundColor(.white)
                                
                                Text(member.role.displayLabel)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if member.id == appState.currentUserID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(red: 32/255, green: 32/255, blue: 36/255))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Family")
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
        }
    }
}

#Preview {
    FamilyView()
        .environmentObject(AppState())
}
