//
//  DashboardView.swift
//  AemtliApp
//
//  Refactored with complete design system integration
//  Updated: October 2025
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xLarge) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Main Content
                    Group {
                        if appState.chores.isEmpty {
                            emptyStateView
                        } else {
                            dashboardContent
                        }
                    }
                }
                .padding(AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.xLarge)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
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
    
    // MARK: - Welcome Header
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
            Text("Welcome back!")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            if let currentUser = appState.currentUser {
                Text(currentUser.name)
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundColor(AppTheme.Colors.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome back, \(appState.currentUser?.name ?? "User")")
    }
    
    // MARK: - Dashboard Content
    
    private var dashboardContent: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Progress Ring Section
            ProgressRing(progress: progressPercentage, size: 220)
                .padding(.vertical, AppTheme.Spacing.medium)
            
            // Today's Tasks Section
            if !appState.chores.isEmpty {
                todayTasksSection
            }
        }
    }
    
    // MARK: - Today's Tasks Section
    
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Today's Tasks")
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(appState.chores) { chore in
                    TaskSummaryCard(
                        title: chore.title,
                        targetValue: 1,
                        currentValue: chore.isDone ? 1 : 0,
                        isCompleted: chore.isDone
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "No Tasks Today",
            message: appState.isCurrentUserParent
                ? "Create your first chore from the Tasks tab to get started!"
                : "You're all set! Check back later for new tasks."
        )
        .frame(minHeight: 400)
    }
    
    // MARK: - Computed Properties
    
    private var progressPercentage: Double {
        let totalChores = Double(appState.chores.count)
        let completedChores = Double(appState.chores.filter { $0.isDone }.count)
        return totalChores > 0 ? completedChores / totalChores : 0
    }
}

// MARK: - Previews

#Preview("With Tasks") {
    DashboardView()
        .environmentObject(AppState())
}

#Preview("Empty State") {
    let appState = AppState()
    appState.chores = []
    return DashboardView()
        .environmentObject(appState)
}

#Preview("All Completed") {
    let appState = AppState()
    Task {
        await appState.loadChores()
    }
    // Simulate all tasks completed
    for i in 0..<appState.chores.count {
        appState.chores[i].isDone = true
    }
    return DashboardView()
        .environmentObject(appState)
}
