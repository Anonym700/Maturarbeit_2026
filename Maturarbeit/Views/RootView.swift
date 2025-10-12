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
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Übersicht", systemImage: "house.fill")
                }
            
            ChoresView_Refactored()
                .tabItem {
                    Label("Aufgaben", systemImage: "checkmark.circle.fill")
                }
            
            FamilyView()
                .tabItem {
                    Label("Familie", systemImage: "person.3.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.Colors.accent)
        .environmentObject(appState)
        .environmentObject(themeManager)
        .preferredColorScheme(themeManager.getColorScheme())
    }
}

#Preview {
    RootView()
}
