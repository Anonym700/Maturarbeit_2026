//
//  SettingsView.swift
//  AemtliApp
//
//  Refactored with complete design system integration
//  Updated: October 2025
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthChecker: CloudKitHealthChecker
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var showingResetConfirmation = false
    @State private var showingThemeSheet = false
    @State private var showingHelpSheet = false
    @State private var reloadState: ReloadButtonState = .idle
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xLarge) {
                    #if DEBUG
                    // CloudKit Health Status (DEBUG only)
                    cloudKitStatusSection
                    #endif
                    
                    // App Settings Section
                    appSettingsSection
                    
                    // About Section
                    aboutSection
                    
                    // Version Info
                    versionInfo
                }
                .padding(AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.xLarge)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let currentUser = appState.currentUser {
                        RoleBadge(role: currentUser.role.displayLabel)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ReloadButton(state: $reloadState) {
                        await appState.reloadAllData()
                    }
                }
            }
        }
    }
    
    // MARK: - CloudKit Status Section (DEBUG)
    
    #if DEBUG
    private var cloudKitStatusSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("CloudKit Status")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            HStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: healthChecker.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(healthChecker.isHealthy ? .green : .red)
                    .font(.title3)
                
                Text(healthChecker.healthMessage)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                Button("Erneut prüfen") {
                    Task {
                        await healthChecker.performHealthCheck()
                    }
                }
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.accent)
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    #endif
    
    // MARK: - App Settings Section
    
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("App-Einstellungen")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: AppTheme.Spacing.small) {
                Button(action: { showingThemeSheet = true }) {
                    SettingRow(
                        icon: "paintbrush.fill",
                        title: "Erscheinungsbild",
                        value: themeManager.themeMode.displayName
                    )
                }
                
                Toggle(isOn: $notificationsEnabled) {
                    HStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppTheme.Colors.accent)
                            .font(.title3)
                            .frame(width: 32)
                        
                        Text("Benachrichtigungen")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.text)
                    }
                }
                .tint(AppTheme.Colors.accent)
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
                
                Button(action: { showingResetConfirmation = true }) {
                    SettingRow(
                        icon: "arrow.counterclockwise",
                        title: "Tägliche Aufgaben zurücksetzen",
                        value: nil
                    )
                }
                
                Button(action: { 
                    // Force app restart with fresh data
                    UserDefaults.standard.set("1.0", forKey: "appDataVersion")
                    exit(0)
                }) {
                    SettingRow(
                        icon: "trash.circle.fill",
                        title: "Alle Daten löschen & Neustart",
                        value: nil
                    )
                }
                
                Button(action: { showingHelpSheet = true }) {
                    SettingRow(
                        icon: "questionmark.circle.fill",
                        title: "Hilfe & Support"
                    )
                }
            }
        }
        .sheet(isPresented: $showingThemeSheet) {
            ThemeSelectionSheet()
        }
        .sheet(isPresented: $showingHelpSheet) {
            HelpSupportSheet()
        }
        .alert("Tägliche Aufgaben zurücksetzen", isPresented: $showingResetConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Zurücksetzen", role: .destructive) {
                Task {
                    await appState.resetDailyTasks()
                }
            }
        } message: {
            Text("Dies setzt alle Aufgaben auf unvollständig zurück. Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.accent)
                .accessibilityHidden(true)
            
            VStack(spacing: AppTheme.Spacing.xSmall) {
                Text("Über Ämtlis")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("Eine einfache Familien-Ämtli-App zur Verwaltung täglicher Aufgaben und Verantwortlichkeiten. Entwickelt mit SwiftUI für iOS 17+.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppTheme.Spacing.large)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Version Info
    
    private var versionInfo: some View {
        HStack {
            Spacer()
            VStack(spacing: AppTheme.Spacing.xxSmall) {
                Text("Version 1.0.0")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                
                Text("© 2025 Ämtlis")
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Setting Row Component

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
        HStack(spacing: AppTheme.Spacing.medium) {
            // Icon
            Image(systemName: icon)
                .foregroundColor(AppTheme.Colors.accent)
                .font(.title3)
                .frame(width: 32)
                .accessibilityHidden(true)
            
            // Title
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.text)
            
            Spacer()
            
            // Value & Chevron
            HStack(spacing: AppTheme.Spacing.xxSmall) {
                if let value = value {
                    Text(value)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .frame(minHeight: AppTheme.Layout.minTapTarget)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(value != nil ? "\(title), \(value!)" : title)
        .accessibilityHint("Doppeltippen zum Öffnen")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Theme Selection Sheet

struct ThemeSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Wähle das bevorzugte Erscheinungsbild für die App.")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.vertical, AppTheme.Spacing.xxSmall)
                } header: {
                    Text("Erscheinungsbild")
                }
                
                Section {
                    ForEach(ThemeMode.allCases) { mode in
                        ThemeOptionRow(
                            mode: mode,
                            isSelected: themeManager.themeMode == mode
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                themeManager.themeMode = mode
                            }
                        }
                    }
                }
            }
            .navigationTitle("Theme-Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Theme Option Row

struct ThemeOptionRow: View {
    let mode: ThemeMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Icon
                Image(systemName: mode.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.textSecondary)
                    .frame(width: 32)
                
                // Text content
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                    Text(mode.displayName)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text(mode.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.Colors.accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, AppTheme.Spacing.xxSmall)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Help & Support Sheet

struct HelpSupportSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Erste Schritte") {
                    HelpRow(
                        icon: "plus.circle.fill",
                        title: "Aufgaben erstellen",
                        description: "Tippe auf den + Button um eine neue Aufgabe zu erstellen und sie Familienmitgliedern zuzuweisen."
                    )
                    
                    HelpRow(
                        icon: "checkmark.circle.fill",
                        title: "Aufgaben erledigen",
                        description: "Tippe auf den Kreis neben einer Aufgabe um sie als erledigt zu markieren."
                    )
                    
                    HelpRow(
                        icon: "trash.fill",
                        title: "Aufgaben löschen",
                        description: "Drücke lange auf eine Aufgabe und wähle Löschen aus dem Menü."
                    )
                }
                
                Section("Täglicher Reset") {
                    HelpRow(
                        icon: "clock.fill",
                        title: "Automatischer Reset",
                        description: "Aufgaben werden automatisch um Mitternacht (00:00) jeden Tag zurückgesetzt."
                    )
                    
                    HelpRow(
                        icon: "arrow.counterclockwise",
                        title: "Manueller Reset",
                        description: "Du kannst Aufgaben jederzeit manuell in den Einstellungen zurücksetzen."
                    )
                }
                
                Section("Kontakt") {
                    Link(destination: URL(string: "mailto:support@aemtliapp.com")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppTheme.Colors.accent)
                            Text("E-Mail Support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("Hilfe & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Help Row Component

struct HelpRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Text(description)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxSmall)
    }
}

// MARK: - Previews

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager.shared)
        .environmentObject(CloudKitHealthChecker())
}

#Preview("Dark Mode") {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager.shared)
        .environmentObject(CloudKitHealthChecker())
        .preferredColorScheme(.dark)
}

#Preview("Theme Sheet") {
    ThemeSelectionSheet()
        .environmentObject(ThemeManager.shared)
}

#Preview("Help Sheet") {
    HelpSupportSheet()
}
