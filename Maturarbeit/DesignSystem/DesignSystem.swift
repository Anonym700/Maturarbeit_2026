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

/// Role badge (Parent/Child) displayed in navigation bar
struct RoleBadge: View {
    let role: String
    
    var body: some View {
        Text(role)
            .font(AppTheme.Typography.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.xxSmall)
            .background(AppTheme.Colors.accent)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.CornerRadius.small)
            .accessibilityLabel("\(role) user")
    }
}

/// Points badge showing chore point value
struct ChorePointsBadge: View {
    let points: Int
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxSmall) {
            Image(systemName: "star.fill")
                .font(.caption2)
            Text("\(points) pts")
                .font(AppTheme.Typography.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, AppTheme.Spacing.xSmall)
        .padding(.vertical, AppTheme.Spacing.xxSmall)
        .background(AppTheme.Colors.accent.opacity(0.15))
        .foregroundColor(AppTheme.Colors.accent)
        .cornerRadius(AppTheme.CornerRadius.small)
        .accessibilityLabel("\(points) points")
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
                
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    ChorePointsBadge(points: chore.points)
                    
                    if let memberName = memberName {
                        Text("•")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Text(memberName)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
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

