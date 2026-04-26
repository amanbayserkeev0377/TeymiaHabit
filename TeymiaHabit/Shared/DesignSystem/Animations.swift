import SwiftUI

extension Animation {
    // MARK: - Theme
    static let themeSpring = Animation.spring(response: 0.6, dampingFraction: 0.7)
    static let themeBounce = Animation.bouncy(duration: 0.6, extraBounce: 0.1)
}
