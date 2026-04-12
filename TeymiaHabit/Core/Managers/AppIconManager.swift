import SwiftUI

@MainActor
@Observable
final class AppIconManager {
    var currentIcon: AppIcon
    
    init() {
        #if os(iOS)
        let iconName = UIApplication.shared.alternateIconName
        if let iconName, let icon = AppIcon(rawValue: iconName) {
            self.currentIcon = icon
        } else {
            self.currentIcon = .main
        }
        #else
        self.currentIcon = .main
        #endif
    }
    
    func setAppIcon(_ icon: AppIcon) {
        #if os(iOS)
        let iconName: String? = (icon == .main) ? nil : icon.rawValue
        
        guard UIApplication.shared.alternateIconName != iconName else { return }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if error == nil {
                Task { @MainActor in
                    self.currentIcon = icon
                }
            }
        }
        #endif
    }
}
