import SwiftUI
import UIKit

/// Centralized haptic feedback manager with user preference support
final class HapticManager {
    static let shared = HapticManager()
    
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    
    private init() {}
    
    func play(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(feedbackType)
    }
    
    func playSelection() {
        guard hapticsEnabled else { return }
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticsEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
