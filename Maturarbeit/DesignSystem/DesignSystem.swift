//
//  DesignSystem.swift
//  AemtliApp
//
//  Reusable SwiftUI components following Apple HIG
//  Updated: October 2025
//

import SwiftUI

// MARK: - Buttons

/// Primary button with purple accent background
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isEnabled: Bool = true
    
    init(_ title: String, icon: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xSmall) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(AppTheme.Typography.headline)
                }
                Text(title)
                    .font(AppTheme.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Layout.buttonHeight)
            .foregroundColor(.white)
            .background(isEnabled ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(AppTheme.Animation.quick, value: isEnabled)
    }
}

/// Secondary button with outline style
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xSmall) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(AppTheme.Typography.headline)
                }
                Text(title)
                    .font(AppTheme.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Layout.buttonHeight)
            .foregroundColor(AppTheme.Colors.accent)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.accent, lineWidth: 2)
            )
        }
    }
}

/// Floating Action Button (FAB)
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var accessibilityLabel: String
    
    init(icon: String, accessibilityLabel: String, action: @escaping () -> Void) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(AppTheme.Colors.accent)
                .clipShape(Circle())
                .mediumShadow()
        }
        .accessibilityLabel(accessibilityLabel)
        .scaleEffect(1.0)
    }
}

// MARK: - Cards

/// Standard card container with padding and background
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(AppTheme.Layout.cardPadding)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Badges

/// Role badge (Parent/Child) displayed in navigation bar - informational, not interactive
struct RoleBadge: View {
    let role: String
    
    var body: some View {
        Text(role)
            .font(AppTheme.Typography.subheadline)
            .fontWeight(.medium)
            .foregroundColor(AppTheme.Colors.text)
            .accessibilityLabel("Current user: \(role)")
            .accessibilityAddTraits(.isStaticText)
            .allowsHitTesting(false)
    }
}


// MARK: - Empty States

/// Empty state view with icon, text, and optional action button
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .padding(.bottom, AppTheme.Spacing.xSmall)
            
            VStack(spacing: AppTheme.Spacing.xSmall) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.text)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xLarge)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.horizontal, AppTheme.Spacing.xxLarge)
                    .padding(.top, AppTheme.Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
    }
}

// MARK: - Loading States

/// Loading spinner with optional message
struct LoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.Colors.accent)
            
            if let message = message {
                Text(message)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
    }
}

// MARK: - Dividers

/// Horizontal divider with theme color
struct ThemeDivider: View {
    var body: some View {
        Divider()
            .background(AppTheme.Colors.separator)
    }
}

// MARK: - Section Headers

/// Standard section header with title
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(AppTheme.Typography.headline)
            .foregroundColor(AppTheme.Colors.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.top, AppTheme.Spacing.large)
            .padding(.bottom, AppTheme.Spacing.xSmall)
    }
}

// MARK: - Chore Components

/// Reusable chore row component
struct ChoreRow: View {
    let chore: Chore
    let memberName: String?
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Button(action: onToggle) {
                Image(systemName: chore.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(chore.isDone ? AppTheme.Colors.success : AppTheme.Colors.accent)
                    .frame(width: AppTheme.Layout.minTapTarget, height: AppTheme.Layout.minTapTarget)
            }
            .accessibilityLabel(chore.isDone ? "Completed" : "Not completed")
            .accessibilityHint("Double-tap to toggle completion")
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(chore.title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.text)
                    .strikethrough(chore.isDone, color: AppTheme.Colors.textSecondary)
                
                if let memberName = memberName {
                    Text(memberName)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Progress Ring

/// Circular progress ring with percentage display
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    var showCheckmark: Bool = true
    
    init(progress: Double, lineWidth: CGFloat = 12, size: CGFloat = 200, showCheckmark: Bool = true) {
        self.progress = min(max(progress, 0), 1) // Clamp between 0 and 1
        self.lineWidth = lineWidth
        self.size = size
        self.showCheckmark = showCheckmark
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(AppTheme.Colors.textTertiary.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppTheme.Colors.accent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(AppTheme.Animation.spring, value: progress)
            
            // Center content
            VStack(spacing: AppTheme.Spacing.xxSmall) {
                if progress >= 1.0 && showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: size * 0.3))
                        .foregroundColor(AppTheme.Colors.success)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.text)
                }
            }
        }
        .accessibilityLabel("Progress: \(Int(progress * 100)) percent complete")
        .accessibilityValue(progress >= 1.0 ? "All tasks completed" : "\(Int(progress * 100)) percent")
    }
}

// MARK: - Stats Card

/// Statistics card with icon, value, and label
struct StatsCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    init(icon: String, value: String, label: String, color: Color = AppTheme.Colors.accent) {
        self.icon = icon
        self.value = value
        self.label = label
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.text)
            
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Task Summary Card

/// Dashboard task card with target icon and completion status
struct TaskSummaryCard: View {
    let title: String
    let targetValue: Int
    let currentValue: Int
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Icon
            Image(systemName: "target")
                .font(.title2)
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: AppTheme.Layout.minTapTarget, height: AppTheme.Layout.minTapTarget)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("Goal: \(targetValue)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Status indicator
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.Colors.success)
                    .accessibilityLabel("Completed")
            } else {
                Text("\(currentValue)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.text)
                    .accessibilityLabel("Progress: \(currentValue) of \(targetValue)")
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Error View

/// Error state view with retry action
struct ErrorView: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)?
    
    init(title: String = "Something Went Wrong", message: String, retryAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.error)
                .padding(.bottom, AppTheme.Spacing.xSmall)
            
            VStack(spacing: AppTheme.Spacing.xSmall) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.text)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xLarge)
            }
            
            if let retryAction = retryAction {
                PrimaryButton("Try Again", icon: "arrow.clockwise", action: retryAction)
                    .padding(.horizontal, AppTheme.Spacing.xxLarge)
                    .padding(.top, AppTheme.Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
    }
}

// MARK: - Reload Button

/// State for reload button animation
enum ReloadButtonState {
    case idle
    case loading
    case success
}

/// Reload button with spinner and success animation
struct ReloadButton: View {
    @Binding var state: ReloadButtonState
    let action: () async -> Void
    
    var body: some View {
        Button(action: {
            guard state == .idle else { return }
            
            Task {
                state = .loading
                await action()
                state = .success
                
                // Reset to idle after showing success for 1.5 seconds
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation {
                    state = .idle
                }
            }
        }) {
            Group {
                switch state {
                case .idle:
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(AppTheme.Colors.accent)
                        .frame(width: 24, height: 24)
                        .transition(.opacity)
                    
                case .loading:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.1)
                        .tint(AppTheme.Colors.accent)
                        .frame(width: 24, height: 24)
                        .transition(.opacity)
                    
                case .success:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.Colors.success)
                        .frame(width: 24, height: 24)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: state)
        }
        .disabled(state != .idle)
        .accessibilityLabel(state == .loading ? "Loading" : state == .success ? "Success" : "Reload data")
    }
}

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: 16) {
        PrimaryButton("Save Changes", icon: "checkmark", action: {})
        SecondaryButton("Cancel", icon: "xmark", action: {})
        FloatingActionButton(icon: "plus", accessibilityLabel: "Add item", action: {})
    }
    .padding()
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "tray",
        title: "No Chores Yet",
        message: "Get started by creating your first chore!",
        actionTitle: "Add Chore",
        action: {}
    )
}

#Preview("Loading") {
    LoadingView(message: "Loading chores...")
}

#Preview("Progress Ring") {
    VStack(spacing: 40) {
        ProgressRing(progress: 0.0)
        ProgressRing(progress: 0.65)
        ProgressRing(progress: 1.0)
    }
    .padding()
}

#Preview("Stats Card") {
    HStack(spacing: 16) {
        StatsCard(icon: "checkmark.circle.fill", value: "8", label: "Completed")
        StatsCard(icon: "clock", value: "3", label: "Pending", color: .orange)
    }
    .padding()
}

#Preview("Error View") {
    ErrorView(
        message: "Unable to load your data. Please check your connection and try again.",
        retryAction: {}
    )
}

