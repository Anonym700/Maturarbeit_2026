//
//  FamilyView.swift
//  AemtliApp
//
//  Refactored with complete design system integration
//  Updated: October 2025
//

import SwiftUI

struct FamilyView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xLarge) {
                    // Current User Selector Section
                    currentUserSection
                    
                    // Family Members List Section
                    familyMembersSection
                }
                .padding(AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.xLarge)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Family")
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
    
    // MARK: - Current User Section
    
    private var currentUserSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Current User")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
                .accessibilityAddTraits(.isHeader)
            
            Picker("Select User", selection: $appState.currentUserID) {
                ForEach(appState.members) { member in
                    Text("\(member.name) (\(member.role.displayLabel))")
                        .tag(member.id)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .accessibilityLabel("Switch active user")
            .accessibilityHint("Select which family member is using the app")
        }
    }
    
    // MARK: - Family Members Section
    
    private var familyMembersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Family Members")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(appState.members) { member in
                    FamilyMemberCard(
                        member: member,
                        isCurrentUser: member.id == appState.currentUserID
                    )
                }
            }
        }
    }
}

// MARK: - Family Member Card

struct FamilyMemberCard: View {
    let member: FamilyMember
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Member Icon
            Image(systemName: memberIcon)
                .font(.title2)
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: AppTheme.Layout.minTapTarget, height: AppTheme.Layout.minTapTarget)
                .background(AppTheme.Colors.accent.opacity(0.1))
                .clipShape(Circle())
                .accessibilityHidden(true)
            
            // Member Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(member.name)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.text)
                
                Text(member.role.displayLabel)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Active Indicator
            if isCurrentUser {
                HStack(spacing: AppTheme.Spacing.xxSmall) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.success)
                    Text("Active")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.success)
                }
                .accessibilityLabel("Currently active user")
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.name), \(member.role.displayLabel)\(isCurrentUser ? ", active" : "")")
    }
    
    private var memberIcon: String {
        switch member.role {
        case .parent:
            return "person.crop.circle.fill"
        case .child:
            return "figure.wave"
        }
    }
}

// MARK: - Previews

#Preview {
    FamilyView()
        .environmentObject(AppState())
}

#Preview("Dark Mode") {
    FamilyView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
