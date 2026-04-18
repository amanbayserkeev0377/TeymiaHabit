import SwiftUI

enum ThemeMode: Int, CaseIterable {
    case system = 0, light, dark
    
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
        case .system: "iphone"
        case .light:  "sun.max"
        case .dark:   "moon.stars"
        }
    }
}
