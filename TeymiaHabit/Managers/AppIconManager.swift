import SwiftUI
import UIKit
import OSLog

@MainActor
@Observable
final class AppIconManager {
    static let shared = AppIconManager()
    
    var currentIcon: AppIcon
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TeymiaHabit", category: "AppIconManager")
    
    private init() {
        let iconName = UIApplication.shared.alternateIconName
        
        if let iconName, let icon = AppIcon(rawValue: iconName) {
            currentIcon = icon
        } else {
            currentIcon = .main
        }
    }
    
    /// Set new app icon
    func setAppIcon(_ icon: AppIcon) {
        // Don't allow setting Pro icons if user is not Pro
        guard !icon.requiresPro || ProManager.shared.isPro else {
            logger.warning("Cannot set Pro icon '\(icon.rawValue)' without Pro status")
            return
        }
        
        // Set icon name to nil for primary icon
        let iconName: String? = (icon == .main) ? nil : icon.rawValue
        
        // Avoid setting if already using this icon
        guard UIApplication.shared.alternateIconName != iconName else { return }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error {
                self.logger.error("Failed to set app icon: \(error)")
            }
        }
        
        // Update immediately like Apple does
        currentIcon = icon
    }
}
