import SwiftUI
import UIKit

/// Centralized haptic feedback manager for the app
/// Provides consistent haptic feedback with user preference support
final class HapticManager {
    static let shared = HapticManager()
    
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    
    private init() {}
    
    /// Play notification feedback (success, error, warning)
    func play(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(feedbackType)
    }
    
    /// Play selection feedback (light tap for selections and navigation)
    func playSelection() {
        guard hapticsEnabled else { return }
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Play impact feedback (for button presses and interactions)
    func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticsEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
