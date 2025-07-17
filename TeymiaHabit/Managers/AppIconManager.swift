import SwiftUI
import UIKit

// MARK: - AppIcon Enum
// Defines app icons with their properties
enum AppIcon: Hashable, Identifiable {
    // MARK: - Cases
    case main           // Default app icon
    case light(name: String)
    case dark(name: String)
    case minimalLight(name: String)
    case minimalDark(name: String)
    case paper(name: String)
    case silverBlue(name: String)
    case clockDark(name: String)
    case clockLight(name: String)
    
    // MARK: - All Icons
    // List of all available icons
    static let allIcons: [AppIcon] = [
        .main,
        .light(name: "AppIconLight"),
        .dark(name: "AppIconDark"),
        .minimalLight(name: "AppIconMinimalLight"),
        .minimalDark(name: "AppIconMinimalDark"),
        .paper(name: "AppIconPaper"),
        .silverBlue(name: "AppIconSilverBlue"),
        .clockDark(name: "AppIconClockDark"),
        .clockLight(name: "AppIconClockLight")
    ]
    
    // MARK: - ID
    // Unique identifier for each icon
    var id: String {
        switch self {
        case .main: return "main"
        case .light(let name): return name
        case .dark(let name): return name
        case .minimalLight(let name): return name
        case .minimalDark(let name): return name
        case .paper(let name): return name
        case .silverBlue(let name): return name
        case .clockDark(let name): return name
        case .clockLight(let name): return name
        }
    }
    
    // MARK: - AppIconSet Name
    // Name for AppIconSet in Assets.xcassets (nil for default icon)
    var name: String? {
        switch self {
        case .main: return nil
        case .light(let name): return name
        case .dark(let name): return name
        case .minimalLight(let name): return name
        case .minimalDark(let name): return name
        case .paper(let name): return name
        case .silverBlue(let name): return name
        case .clockDark(let name): return name
        case .clockLight(let name): return name
        }
    }
    
    // MARK: - Preview Image
    // Name for ImageSet in Assets.xcassets for UI preview
    var preview: String {
        switch self {
        case .main: return "app_icon_main"
        case .light(_): return "app_icon_light"
        case .dark(_): return "app_icon_dark"
        case .minimalLight(_): return "app_icon_minimal_light"
        case .minimalDark(_): return "app_icon_minimal_dark"
        case .paper(_): return "app_icon_paper"
        case .silverBlue(_): return "app_icon_silver_blue"
        case .clockDark(_): return "app_icon_clock_dark"
        case .clockLight(_): return "app_icon_clock_light"
        }
    }
    
    // MARK: - Pro Features
    var isBasicIcon: Bool {
        switch self {
        case .main, .light, .dark:
            return true
        default:
            return false
        }
    }

    var requiresPro: Bool {
        return !isBasicIcon
    }
    
}

// MARK: - AppIconManager Class
// Manages app icon switching and UI updates
class AppIconManager: ObservableObject {
    static let shared = AppIconManager()
    
    // Current icon for UI updates
    @Published private(set) var currentIcon: AppIcon
    
    private init() {
        currentIcon = Self.getCurrentAppIcon()
    }
    
    // Gets the currently set app icon
    static func getCurrentAppIcon() -> AppIcon {
        if let alternateIconName = UIApplication.shared.alternateIconName {
            if let matchingIcon = AppIcon.allIcons.first(where: { $0.name == alternateIconName }) {
                return matchingIcon
            }
        }
        return .main
    }
    
    // Sets a new app icon
    func setAppIcon(_ icon: AppIcon) {
        print("Setting icon: \(icon.id)")
        applySpecificIcon(icon.name)
        currentIcon = icon
    }
    
    // Applies the specified icon
    private func applySpecificIcon(_ iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Device does not support alternate icons")
            return
        }
        
        let currentIconName = UIApplication.shared.alternateIconName
        
        // Skip if the icon is already set
        if currentIconName == iconName {
            print("Icon \(String(describing: iconName)) is already set")
            return
        }
        
        // Apply the icon
        UIApplication.shared.setAlternateIconName(iconName) { [weak self] error in
            if let error = error {
                print("Error setting icon: \(error.localizedDescription)")
            } else {
                print("Successfully set icon: \(String(describing: iconName))")
                if let self = self {
                    Task { @MainActor in
                        self.currentIcon = Self.getCurrentAppIcon()
                    }
                }
            }
        }
    }
}
