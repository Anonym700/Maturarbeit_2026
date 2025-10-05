//
//  RootView.swift
//  AemtliApp
//
//  Main tab navigation container with design system integration
//  Updated: October 2025
//

import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            ChoresView_Refactored()
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle.fill")
                }
            
            FamilyView()
                .tabItem {
                    Label("Family", systemImage: "person.3.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.Colors.accent)
        .environmentObject(appState)
    }
}

#Preview {
    RootView()
}
