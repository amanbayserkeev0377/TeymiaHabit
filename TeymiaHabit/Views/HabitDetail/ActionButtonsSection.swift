import SwiftUI

struct ActionButtonsSection: View {
    let habit: Habit
    let isTimerRunning: Bool
    
    var onReset: () -> Void
    var onTimerToggle: () -> Void
    var onManualEntry: () -> Void
    
    @State private var resetPressed = false
    @State private var togglePressed = false
    @State private var manualEntryPressed = false
    
    @Environment(\.colorScheme) private var colorScheme
        
    var body: some View {
        HStack(spacing: 18) {
            // 1. Reset
            Button {
                resetPressed.toggle()
                onReset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 24))
                    .withHabitColor(habit)
                    .frame(minWidth: 44, minHeight: 44)
                    .symbolEffect(.rotate, options: .speed(4.5), value: resetPressed)
            }
            .errorHaptic(trigger: resetPressed)
            
            if habit.type == .time {
                // 2. Play/Pause - ✅ ИСПРАВЛЕННЫЙ градиент с единой логикой
                Button {
                    print("🎯 Timer button tapped")
                    togglePressed.toggle()
                    onTimerToggle()
                } label: {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 42))
                        .contentTransition(.symbolEffect(.replace, options: .speed(2.5)))
                        .foregroundStyle(adaptivePlayButtonGradient)
                        .frame(minWidth: 52, minHeight: 52)
                }
                .hapticFeedback(.impact(weight: .medium), trigger: togglePressed)
            }
            
            // 3. Manual Entry
            Button {
                manualEntryPressed.toggle()
                onManualEntry()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .withHabitColor(habit)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .hapticFeedback(.impact(weight: .medium), trigger: manualEntryPressed)
            .accessibilityLabel("manual_entry_button_label".localized)
        }
        .frame(maxWidth: 300)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }
    
    // MARK: - Computed Properties
    
    /// ✅ ИСПРАВЛЕННЫЙ адаптивный градиент с единой логикой приложения
    private var adaptivePlayButtonGradient: LinearGradient {
        return habit.iconColor.adaptiveGradient(
            for: colorScheme)
    }
}
