import SwiftUI
#if canImport(UIKit)
import UIKit

enum AppFont {
    static func configureAppearance() {
        let appTint = UIColor(DS.Colors.appPrimary)
        
        // MARK: - Fonts
        let titleFont = UIFont.rounded(ofSize: 18, weight: .semibold)
        let largeTitleFont = UIFont.rounded(ofSize: 34, weight: .bold)
        
        // MARK: - Navigation Bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: appTint
        ]
        let largeAttributes: [NSAttributedString.Key: Any] = [
            .font: largeTitleFont,
            .foregroundColor: appTint
        ]
        
        navAppearance.titleTextAttributes = attributes
        navAppearance.largeTitleTextAttributes = largeAttributes
        
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: appTint]
        
        navAppearance.buttonAppearance = buttonAppearance
        navAppearance.backButtonAppearance = buttonAppearance
        
        let appearance = navAppearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = appTint
        UIBarButtonItem.appearance().tintColor = appTint
        
        // MARK: - Tab Bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = appTint
        
        // MARK: - Toolbar
        UIToolbar.appearance().tintColor = appTint
    }
}

extension UIFont {
    static func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return systemFont
    }
}
#endif
