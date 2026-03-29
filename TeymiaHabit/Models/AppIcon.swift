import Foundation

enum AppIcon: String, CaseIterable, Identifiable {
    case main = "AppIcon"
    case dark = "AppIconDark"
    case orange = "AppIconOrange"
    case mint = "AppIconMint"
    case raspberry = "AppIconRaspberry"
    case lime = "AppIconLime"
    case yellow = "AppIconYellow"
    case indigo = "AppIconIndigo"
    case cyan = "AppIconCyan"
    
    var id: String { rawValue }
    
    var title: LocalizedStringResource {
        switch self {
        case .main: return "appicon_main"
        case .dark: return "appicon_dark"
        case .orange: return "appicon_orange"
        case .mint: return "appicon_mint"
        case .raspberry: return "appicon_raspberry"
        case .lime: return "appicon_lime"
        case .yellow: return "appicon_yellow"
        case .indigo: return "appicon_indigo"
        case .cyan: return "appicon_cyan"
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
        case .orange, .mint, .raspberry, .lime, .yellow, .indigo, .cyan:
            return true   // Pro icons
        }
    }
}
