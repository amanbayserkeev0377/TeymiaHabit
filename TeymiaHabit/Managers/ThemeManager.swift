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
        case .system: "swirl.circle.righthalf.filled"
        case .light:  "sun.max"
        case .dark:   "moon.stars"
        }
    }
}

enum AppTheme: String, CaseIterable {
    case soft, neutral, contrast
    
    var localizedName: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: "apptheme_\(self.rawValue)")
    }
}

@Observable
class ThemeManager {
    static let shared = ThemeManager()
    
    var currentTheme: AppTheme {
        didSet { UserDefaults.standard.set(currentTheme.rawValue, forKey: "currentTheme") }
    }
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "currentTheme") ?? "soft"
        self.currentTheme = AppTheme(rawValue: saved) ?? .soft
    }
    
    func colorName(for type: String) -> String {
        return "\(currentTheme.rawValue)\(type)"
    }
}
