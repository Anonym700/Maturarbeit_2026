//
//  RootView.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            ChoresView()
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Tasks")
                }
            
            FamilyView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Family")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .accentColor(.purple)
        .environmentObject(appState)
    }
}

#Preview {
    RootView()
}
