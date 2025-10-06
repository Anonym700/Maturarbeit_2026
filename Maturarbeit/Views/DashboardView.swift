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
            // For parents: show children's progress
            if appState.isCurrentUserParent {
                childrenProgressSection
            } else {
                // For children: show their own progress ring
                ProgressRing(progress: progressPercentage, size: 220)
                    .padding(.vertical, AppTheme.Spacing.medium)
            }
            
            // Today's Tasks Section
            if !appState.chores.isEmpty {
                todayTasksSection
            }
        }
    }
    
    // MARK: - Children's Progress Section (for parents)
    
    private var childrenProgressSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Kinder Fortschritt")
            
            VStack(spacing: AppTheme.Spacing.medium) {
                ForEach(children) { child in
                    ChildProgressCard(
                        childName: child.name,
                        completed: completedTasksCount(for: child.id),
                        total: totalTasksCount(for: child.id),
                        progress: progressPercentage(for: child.id)
                    )
                }
            }
        }
    }
    
    // MARK: - Today's Tasks Section
    
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Today's Tasks")
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(visibleChores) { chore in
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
    
    private var children: [FamilyMember] {
        appState.members.filter { $0.role == .child }
    }
    
    /// Filter chores: Children only see their own tasks, Parents see all
    private var visibleChores: [Chore] {
        if appState.isCurrentUserParent {
            return appState.chores
        } else {
            return appState.chores.filter { $0.assignedTo == appState.currentUserID }
        }
    }
    
    private var progressPercentage: Double {
        let totalChores = Double(visibleChores.count)
        let completedChores = Double(visibleChores.filter { $0.isDone }.count)
        return totalChores > 0 ? completedChores / totalChores : 0
    }
    
    private func progressPercentage(for childID: UUID) -> Double {
        let childTasks = appState.chores.filter { $0.assignedTo == childID }
        let total = Double(childTasks.count)
        let completed = Double(childTasks.filter { $0.isDone }.count)
        return total > 0 ? completed / total : 0
    }
    
    private func completedTasksCount(for childID: UUID) -> Int {
        appState.chores.filter { $0.assignedTo == childID && $0.isDone }.count
    }
    
    private func totalTasksCount(for childID: UUID) -> Int {
        appState.chores.filter { $0.assignedTo == childID }.count
    }
}

// MARK: - Child Progress Card

struct ChildProgressCard: View {
    let childName: String
    let completed: Int
    let total: Int
    let progress: Double
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Child Avatar/Icon
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.cardBackground)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(AppTheme.Colors.accent)
            }
            
            // Progress Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(childName)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("\(completed) von \(total) Aufgaben erledigt")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.Colors.cardBackground)
                            .frame(height: 8)
                        
                        // Progress Fill
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.spring(), value: progress)
                    }
                }
                .frame(height: 8)
            }
            
            Spacer()
            
            // Percentage
            Text("\(Int(progress * 100))%")
                .font(AppTheme.Typography.title3)
                .foregroundColor(progressColor)
                .bold()
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: AppTheme.Shadow.small.color, radius: AppTheme.Shadow.small.radius)
    }
    
    private var progressColor: Color {
        if progress >= 0.8 {
            return AppTheme.Colors.success
        } else if progress >= 0.5 {
            return AppTheme.Colors.accent
        } else {
            return AppTheme.Colors.warning
        }
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
