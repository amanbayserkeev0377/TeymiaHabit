import SwiftUI

@MainActor
@Observable
final class AppIconManager {
#if os(iOS)
    var currentIcon: AppIcon
    
    init() {
        let iconName = UIApplication.shared.alternateIconName
        if let iconName, let icon = AppIcon(rawValue: iconName) {
            self.currentIcon = icon
        } else {
            self.currentIcon = .main
        }
    }
    
    func setAppIcon(_ icon: AppIcon) {
        let iconName: String? = (icon == .main) ? nil : icon.rawValue
        
        guard UIApplication.shared.alternateIconName != iconName else { return }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if error == nil {
                Task { @MainActor in
                    self.currentIcon = icon
                }
            }
        }
    }
#endif
}
