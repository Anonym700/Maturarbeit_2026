//
//  ThemeManager.swift
//  AemtliApp
//
//  Global Theme Manager - Manages app-wide theme settings
//  Updated: October 2025
//

import SwiftUI

// MARK: - Theme Mode Enum

enum ThemeMode: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light:
            return "Light Mode"
        case .dark:
            return "Dark Mode"
        case .system:
            return "System Auto"
        }
    }
    
    var icon: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
    
    var description: String {
        switch self {
        case .light:
            return "Always use light appearance"
        case .dark:
            return "Always use dark appearance"
        case .system:
            return "Match system settings"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // Uses system setting
        }
    }
}

// MARK: - Global Theme Manager

class ThemeManager: ObservableObject {
    // Singleton instance for global access
    static let shared = ThemeManager()
    
    // Global theme setting stored in UserDefaults
    @AppStorage("appThemeMode") var themeMode: ThemeMode = .system {
        didSet {
            objectWillChange.send()
            print("🎨 Theme changed to: \(themeMode.displayName)")
        }
    }
    
    private init() {
        print("🎨 ThemeManager initialized with mode: \(themeMode.displayName)")
    }
    
    /// Get the current color scheme based on theme mode
    func getColorScheme() -> ColorScheme? {
        return themeMode.colorScheme
    }
    
    /// Check if current mode is a specific mode
    func isMode(_ mode: ThemeMode) -> Bool {
        return themeMode == mode
    }
}

// MARK: - View Extension for Easy Theme Access

extension View {
    /// Apply the global theme to this view
    func applyAppTheme() -> some View {
        self.preferredColorScheme(ThemeManager.shared.getColorScheme())
    }
}

