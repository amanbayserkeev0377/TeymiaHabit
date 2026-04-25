import SwiftUI

enum ThemeMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .system: "appearance_system"
        case .light:  "appearance_light"
        case .dark:   "appearance_dark"
        }
    }
    
    var iconName: String {
        switch self {
        case .system: "ui-circle.half"
        case .light:  "ui-sun"
        case .dark:   "ui-moon"
        }
    }
    
    func gradient(_ scheme: ColorScheme) -> LinearGradient {
        switch self {
        case .system:
            return scheme == .dark ? darkGradient : lightGradient
        case .light:
            return lightGradient
        case .dark:
            return darkGradient
        }
    }
    
    func glowColor(_ scheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return scheme == .dark ? .indigo : .orange
        case .light:
            return .orange
        case .dark:
            return .indigo
        }
    }
    
    private var lightGradient: LinearGradient {
        LinearGradient(colors: [.sunYellow, .sunOrange], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    private var darkGradient: LinearGradient {
        LinearGradient(colors: [.moonIndigo, .moonPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Domain Model Extension

extension ThemeMode {
    func resolvedIsDark(systemScheme: ColorScheme) -> Bool {
        switch self {
        case .system: return systemScheme == .dark
        case .light:  return false
        case .dark:   return true
        }
    }
}
