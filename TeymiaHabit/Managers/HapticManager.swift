import SwiftUI
import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    
    // ✅ OPTIMIZATION: Pre-initialized generators
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Prepare generators сразу
        prepareGenerators()
    }
    
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Direct Methods (используются в проекте)
    
    func play(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        notificationGenerator.notificationOccurred(feedbackType)
    }
    
    func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactLight.impactOccurred()
        case .rigid:
            impactHeavy.impactOccurred()
        @unknown default:
            impactMedium.impactOccurred()
        }
    }
    
    func playSelection() {
        guard hapticsEnabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    // MARK: - View Modifiers
    
    func sensoryFeedback(_ feedback: SensoryFeedback, trigger: Bool) -> some ViewModifier {
        EnhancedSensoryFeedbackModifier(
            feedback: feedback,
            trigger: trigger,
            isEnabled: hapticsEnabled
        )
    }
}

// MARK: - Enhanced Modifier
private struct EnhancedSensoryFeedbackModifier: ViewModifier {
    let feedback: SensoryFeedback
    let trigger: Bool
    let isEnabled: Bool
    
    @State private var lastTriggerValue: Bool = false
    
    func body(content: Content) -> some View {
        if isEnabled {
            content.sensoryFeedback(feedback, trigger: trigger)
        } else {
            content
        }
    }
}

// MARK: - View Extensions (только нужные)
extension View {
    
    func hapticFeedback(_ feedback: SensoryFeedback, trigger: Bool) -> some View {
        modifier(HapticManager.shared.sensoryFeedback(feedback, trigger: trigger))
    }
    
    // Часто используемые shortcuts
    func increaseHaptic(trigger: Bool) -> some View {
        hapticFeedback(.increase, trigger: trigger)
    }
    
    func decreaseHaptic(trigger: Bool) -> some View {
        hapticFeedback(.decrease, trigger: trigger)
    }
    
    func errorHaptic(trigger: Bool) -> some View {
        hapticFeedback(.error, trigger: trigger)
    }
    
    // Оставляем остальные для совместимости (если где-то используются)
    func successHaptic(trigger: Bool) -> some View {
        hapticFeedback(.success, trigger: trigger)
    }
    
    func selectionHaptic(trigger: Bool) -> some View {
        hapticFeedback(.selection, trigger: trigger)
    }
}
