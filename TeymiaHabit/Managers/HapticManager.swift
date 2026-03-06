import AudioToolbox
import SwiftUI
import UIKit

final class HapticManager {
    static let shared = HapticManager()
    
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    
    private init() {}
    
    func play(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
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
    
    // Vibration
    func playSystemNotificationVibration() {
        guard hapticsEnabled else { return }
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
}
