import SwiftUI

enum DS {
    // MARK: - Colors
    enum Colors {
        static let appPrimary = Color.appPrimary
        static let appSecondary = Color.appSecondary
        static let primaryBackground = Color.primaryBackground
        static let secondaryBackground = Color.secondaryBackground
        static let rowBackground = Color.rowBackground
        
        static let iconOpacity: Double = 0.15
    }
    
    // MARK: - Icon
    enum Icon {
        static let s16: CGFloat = 16
        static let s20: CGFloat = 20
        static let s24: CGFloat = 24
        static let s32: CGFloat = 32
        
        static let backgroundMultiplier: CGFloat = 2
    }
    
    // MARK: - Radius
    enum Radius {
        static let s8: CGFloat = 8
        static let s12: CGFloat = 12
        static let s16: CGFloat = 16
        static let s24: CGFloat = 24
        static let s28: CGFloat = 28
        static let s32: CGFloat = 32
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let s4: CGFloat = 4
        static let s6: CGFloat = 6
        static let s8: CGFloat = 8
        static let s12: CGFloat = 12
        static let s16: CGFloat = 16
        static let s20: CGFloat = 20
        static let s24: CGFloat = 24
        static let s28: CGFloat = 28
        static let s32: CGFloat = 32
    }
    
    // MARK: - Shadows
    enum Shadows {
        struct ShadowConfig {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
        
        static let small = ShadowConfig(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = ShadowConfig(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Animations
    
    enum Animations {
        static let spring = Animation.spring(response: 0.6, dampingFraction: 0.7)
        static let bouncy = Animation.bouncy(duration: 0.5, extraBounce: 0.1)
        static let snappy = Animation.snappy(duration: 0.3)
        static let easeInOut = Animation.easeInOut(duration: 0.35)
    }
    
    // MARK: - Typography
    enum Typography {
        // Helper
        private static func appFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
            return .system(style, design: .rounded).weight(weight)
        }

        // Large Titles
        static let largeTitle = appFont(.largeTitle, weight: .bold)

        // Titles
        static let titleLarge = appFont(.title, weight: .bold)
        static let titleMedium = appFont(.title2, weight: .semibold)
        static let titleSmall = appFont(.title3, weight: .medium)
        
        // Headlines
        static let headline = appFont(.headline, weight: .semibold)
        static let subheadline = appFont(.subheadline, weight: .regular)
        static let subheadlineMedium = appFont(.subheadline, weight: .medium)
        
        // Callout
        static let callout = appFont(.callout, weight: .regular)
        static let calloutMedium = appFont(.callout, weight: .medium)
        static let calloutBold = appFont(.callout, weight: .bold)
        
        // Body
        static let body = appFont(.body, weight: .regular)
        static let bodyMedium = appFont(.body, weight: .medium)
        static let bodyBold = appFont(.body, weight: .bold)
        
        // Footnote
        static let footnote = appFont(.footnote, weight: .regular)
        static let footnoteMedium = appFont(.footnote, weight: .medium)
        static let footnoteBold = appFont(.footnote, weight: .bold)
        
        // Caption
        static let caption = appFont(.caption, weight: .regular)
        static let captionMedium = appFont(.caption, weight: .medium)
        
        // Specialized
        static let rowIcon = appFont(.callout, weight: .medium)
    }
}
