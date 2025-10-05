//
//  AppTheme.swift
//  AemtliApp
//
//  Design System - Centralized theme tokens for spacing, colors, typography, and layout
//  Updated: October 2025
//

import SwiftUI

enum AppTheme {
    
    // MARK: - Colors
    
    enum Colors {
        /// Primary accent color (purple) - used for CTAs, highlights, and branding
        static let accent = Color.purple
        
        /// Main background color - adapts to light/dark mode
        static let background = Color(uiColor: .systemBackground)
        
        /// Secondary background for cards and containers
        static let cardBackground = Color(uiColor: .secondarySystemBackground)
        
        /// Tertiary background for nested elements
        static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
        
        /// Primary text color - adapts to light/dark mode
        static let text = Color.primary
        
        /// Secondary text color for less prominent content
        static let textSecondary = Color.secondary
        
        /// Tertiary text color for hints and placeholders
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        
        /// Success state color (green)
        static let success = Color.green
        
        /// Warning state color (orange)
        static let warning = Color.orange
        
        /// Error state color (red)
        static let error = Color.red
        
        /// Separator/divider color
        static let separator = Color(uiColor: .separator)
    }
    
    // MARK: - Spacing
    
    /// 8pt spacing grid for consistent layouts
    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 40
        static let xxxLarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    /// Consistent corner radius values
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
        static let circle: CGFloat = .infinity
    }
    
    // MARK: - Typography
    
    /// Semantic font styles using iOS system fonts
    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.bold)
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - Layout
    
    /// Layout constants and constraints
    enum Layout {
        /// Minimum tap target size per Apple HIG (44x44pt)
        static let minTapTarget: CGFloat = 44
        
        /// Standard button height
        static let buttonHeight: CGFloat = 48
        
        /// Large button height (for primary CTAs)
        static let largeButtonHeight: CGFloat = 56
        
        /// Standard card/container padding
        static let cardPadding: CGFloat = Spacing.medium
        
        /// Screen edge padding
        static let screenPadding: CGFloat = Spacing.medium
        
        /// Maximum content width for iPad/large screens
        static let maxContentWidth: CGFloat = 600
    }
    
    // MARK: - Animation
    
    /// Standard animation configurations
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
    }
    
    // MARK: - Shadow
    
    /// Elevation shadows for depth
    enum Shadow {
        static let small: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            Color.black.opacity(0.1),
            2,
            0,
            1
        )
        
        static let medium: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            Color.black.opacity(0.12),
            8,
            0,
            4
        )
        
        static let large: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            Color.black.opacity(0.15),
            16,
            0,
            8
        )
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply standard card styling
    func cardStyle() -> some View {
        self
            .padding(AppTheme.Layout.cardPadding)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Apply subtle shadow
    func subtleShadow() -> some View {
        let shadow = AppTheme.Shadow.small
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Apply medium shadow
    func mediumShadow() -> some View {
        let shadow = AppTheme.Shadow.medium
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

