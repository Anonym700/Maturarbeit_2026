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
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var showingResetConfirmation = false
    @State private var showingThemeSheet = false
    @State private var showingHelpSheet = false
    
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let currentUser = appState.currentUser {
                        RoleBadge(role: currentUser.role.displayLabel)
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
            
            if let healthChecker = try? EnvironmentValues().environmentObject as? CloudKitHealthChecker {
                HStack(spacing: AppTheme.Spacing.medium) {
                    Image(systemName: healthChecker.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(healthChecker.isHealthy ? .green : .red)
                        .font(.title3)
                    
                    Text(healthChecker.healthMessage)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Spacer()
                    
                    Button("Re-check") {
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
    }
    #endif
    
    // MARK: - App Settings Section
    
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("App Settings")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: AppTheme.Spacing.small) {
                Button(action: { showingThemeSheet = true }) {
                    SettingRow(
                        icon: "paintbrush.fill",
                        title: "Theme",
                        value: themeManager.themeMode.displayName
                    )
                }
                
                Toggle(isOn: $notificationsEnabled) {
                    HStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppTheme.Colors.accent)
                            .font(.title3)
                            .frame(width: 32)
                        
                        Text("Notifications")
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
                        title: "Reset Daily Tasks",
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
                        title: "Clear All Data & Restart",
                        value: nil
                    )
                }
                
                Button(action: { showingHelpSheet = true }) {
                    SettingRow(
                        icon: "questionmark.circle.fill",
                        title: "Help & Support"
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
        .alert("Reset Daily Tasks", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task {
                    await appState.resetDailyTasks()
                }
            }
        } message: {
            Text("This will reset all tasks to incomplete. This action cannot be undone.")
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
                Text("About AemtliApp")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("A simple family chores app to help manage daily tasks and responsibilities. Built with SwiftUI for iOS 17+.")
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
                
                Text("© 2025 AemtliApp")
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
        .accessibilityHint("Double tap to open")
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
                    Text("Choose your preferred appearance for the app.")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.vertical, AppTheme.Spacing.xxSmall)
                } header: {
                    Text("Appearance")
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
            .navigationTitle("Theme Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
                Section("Getting Started") {
                    HelpRow(
                        icon: "plus.circle.fill",
                        title: "Creating Tasks",
                        description: "Tap the + button to create a new task and assign it to family members."
                    )
                    
                    HelpRow(
                        icon: "checkmark.circle.fill",
                        title: "Completing Tasks",
                        description: "Tap the circle next to a task to mark it as complete."
                    )
                    
                    HelpRow(
                        icon: "trash.fill",
                        title: "Deleting Tasks",
                        description: "Long press on a task and select Delete from the menu."
                    )
                }
                
                Section("Daily Reset") {
                    HelpRow(
                        icon: "clock.fill",
                        title: "Automatic Reset",
                        description: "Tasks automatically reset at midnight (00:00) each day."
                    )
                    
                    HelpRow(
                        icon: "arrow.counterclockwise",
                        title: "Manual Reset",
                        description: "You can manually reset tasks anytime from Settings."
                    )
                }
                
                Section("Contact") {
                    Link(destination: URL(string: "mailto:support@aemtliapp.com")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppTheme.Colors.accent)
                            Text("Email Support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
}

#Preview("Dark Mode") {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager.shared)
        .preferredColorScheme(.dark)
}

#Preview("Theme Sheet") {
    ThemeSelectionSheet()
        .environmentObject(ThemeManager.shared)
}

#Preview("Help Sheet") {
    HelpSupportSheet()
}
