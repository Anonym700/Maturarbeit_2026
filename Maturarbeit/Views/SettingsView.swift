//
//  SettingsView.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("App Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        SettingRow(icon: "paintbrush", title: "Theme", value: "Dark")
                        SettingRow(icon: "bell", title: "Notifications", value: "On")
                        SettingRow(icon: "hand.raised", title: "Privacy", value: "Standard")
                        SettingRow(icon: "questionmark.circle", title: "Help & Support")
                    }
                }
                
                VStack(spacing: 12) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("About AemtliApp")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("A simple family chores app to help manage daily tasks and responsibilities.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color(red: 32/255, green: 32/255, blue: 36/255))
                .cornerRadius(16)
                
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Settings")
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

struct SettingRow: View {
    let icon: String
    let title: String
    let value: String?
    
    init(icon: String, title: String, value: String? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .font(.title2)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(red: 32/255, green: 32/255, blue: 36/255))
        .cornerRadius(12)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
