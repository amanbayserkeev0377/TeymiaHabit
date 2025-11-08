import Foundation

enum AppIcon: String, CaseIterable, Identifiable {
    case main = "AppIcon"
    case light = "AppIcon-Light"
    case dark = "AppIcon-Dark"
    case clockNeon = "AppIcon-ClockNeon"
    case clockLight = "AppIcon-ClockLight"
    case clockDark = "AppIcon-ClockDark"
    
    var id: String { rawValue }
    
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
        case .main, .light, .dark:
            return false  // Free icons
        case .clockNeon, .clockLight, .clockDark:
            return true   // Pro icons
        }
    }
    
    // All icons as array
    static var allIcons: [AppIcon] {
        AppIcon.allCases
    }
}
