import Foundation

enum AppIcon: String, CaseIterable, Identifiable {
    case main = "AppIcon"
    case dark = "AppIconDark"
    case minimal = "AppIconMinimal"
    case minimalDark = "AppIconMinimalDark"
    
    var id: String { rawValue }
    
    var title: LocalizedStringResource {
        switch self {
        case .main: return "appicon_main"
        case .dark: return "appicon_dark"
        case .minimal: return "appicon_minimal"
        case .minimalDark: return "appicon_minimal_dark"
        }
    }
    
    // Name for UIApplication.setAlternateIconName
    var name: String? {
        self == .main ? nil : rawValue
    }
    
    // Preview image name for settings
    var previewImageName: String {
        "Preview-\(rawValue)"
    }
    
    // Check if icon requires Pro
    var requiresPro: Bool {
        switch self {
        case .main, .dark:
            return false  // Free icons
        case .minimal, .minimalDark:
            return true   // Pro icons
        }
    }
}
