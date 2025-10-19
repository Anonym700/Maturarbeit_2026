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
    @State private var reloadState: ReloadButtonState = .idle
    @State private var selectedChild: FamilyMember?
    @State private var showChildDetail = false
    
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
            .navigationTitle("Übersicht")
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
    
    // MARK: - Welcome Header
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
            Text("Willkommen zurück!")
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
        .accessibilityLabel("Willkommen zurück, \(appState.currentUser?.name ?? "Benutzer")")
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
                
                // Show today's tasks for children
                if !visibleChores.isEmpty {
                    todayTasksSection
                }
            }
        }
        .sheet(isPresented: $showChildDetail) {
            if let child = selectedChild {
                ChildDetailView(
                    child: child,
                    chores: appState.chores.filter { $0.assignedTo == child.id },
                    progress: progressPercentage(for: child.id)
                )
                .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Today's Tasks Section (for children)
    
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Heutige Aufgaben")
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(visibleChores) { chore in
                    Button(action: {
                        Task {
                            await appState.toggleChore(chore)
                        }
                    }) {
                        TaskSummaryCard(
                            title: chore.title,
                            targetValue: 1,
                            currentValue: chore.isDone ? 1 : 0,
                            isCompleted: chore.isDone
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!appState.canCompleteChore(chore))
                    .opacity(appState.canCompleteChore(chore) ? 1.0 : 0.6)
                }
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
                    .onTapGesture {
                        selectedChild = child
                        showChildDetail = true
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "Keine Aufgaben",
            message: appState.isCurrentUserParent
                ? "Erstelle deine erste Aufgabe im Aufgaben-Tab!"
                : "Alles erledigt! Schau später wieder vorbei."
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
            
            // Percentage and Chevron
            HStack(spacing: AppTheme.Spacing.small) {
                Text("\(Int(progress * 100))%")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(progressColor)
                    .bold()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
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

// MARK: - Child Detail View

struct ChildDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let child: FamilyMember
    let chores: [Chore]
    let progress: Double
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xLarge) {
                    // Progress Ring
                    VStack(spacing: AppTheme.Spacing.large) {
                        ProgressRing(progress: progress, size: 200)
                        
                        VStack(spacing: AppTheme.Spacing.xSmall) {
                            Text("\(child.name)'s Fortschritt")
                                .font(AppTheme.Typography.title2)
                                .foregroundColor(AppTheme.Colors.text)
                            
                            Text("\(completedCount) von \(chores.count) Aufgaben erledigt")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    .padding(.top, AppTheme.Spacing.large)
                    
                    // Tasks List
                    if !chores.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                            SectionHeader(title: "Aufgaben")
                            
                            VStack(spacing: AppTheme.Spacing.small) {
                                ForEach(chores) { chore in
                                    TaskDetailCard(chore: chore)
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                    } else {
                        EmptyStateView(
                            icon: "checkmark.circle",
                            title: "Keine Aufgaben",
                            message: "\(child.name) hat zurzeit keine zugewiesenen Aufgaben."
                        )
                        .frame(minHeight: 200)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xLarge)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle(child.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                }
            }
        }
    }
    
    private var completedCount: Int {
        chores.filter { $0.isDone }.count
    }
}

// MARK: - Task Detail Card

struct TaskDetailCard: View {
    @EnvironmentObject var appState: AppState
    let chore: Chore
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Checkmark
            Image(systemName: chore.isDone ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(chore.isDone ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
            
            // Task Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(chore.title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.text)
                    .strikethrough(chore.isDone)
                
                HStack(spacing: 6) {
                    // Recurrence
                    if chore.recurrence != .once {
                        HStack(spacing: 3) {
                            Image(systemName: chore.recurrence.icon)
                                .font(.system(size: 10))
                            Text(chore.recurrence.displayName)
                                .font(AppTheme.Typography.caption)
                        }
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Deadline
                    if chore.hasDeadline {
                        if chore.recurrence != .once {
                            Text("•")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(chore.deadlineCountdown)
                                .font(AppTheme.Typography.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(chore.isOverdue ? AppTheme.Colors.error : AppTheme.Colors.warning)
                        .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: AppTheme.Shadow.small.color, radius: AppTheme.Shadow.small.radius)
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
