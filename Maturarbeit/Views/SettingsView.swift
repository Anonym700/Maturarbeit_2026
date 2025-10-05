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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xLarge) {
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
    
    // MARK: - App Settings Section
    
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("App Settings")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: AppTheme.Spacing.small) {
                SettingRow(
                    icon: "paintbrush.fill",
                    title: "Theme",
                    value: colorScheme == .dark ? "Dark" : "Light"
                )
                
                SettingRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    value: "On"
                )
                
                SettingRow(
                    icon: "hand.raised.fill",
                    title: "Privacy",
                    value: "Standard"
                )
                
                SettingRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support"
                )
            }
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

// MARK: - Previews

#Preview {
    SettingsView()
        .environmentObject(AppState())
}

#Preview("Dark Mode") {
    SettingsView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
