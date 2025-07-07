import SwiftUI

struct ActionButtonsSection: View {
    let habit: Habit
    let date: Date
    let isTimerRunning: Bool
    
    var onReset: () -> Void
    var onTimerToggle: () -> Void
    var onManualEntry: () -> Void
    
    @State private var resetPressed = false
    @State private var togglePressed = false
    @State private var manualEntryPressed = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isToday: Bool {
            Calendar.current.isDateInToday(date)
        }
        
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
                    .symbolEffect(.rotate, options: .speed(6.0), value: resetPressed)
            }
            .errorHaptic(trigger: resetPressed)
            
            if habit.type == .time && isToday {
                // 2. Play/Pause - ✅ ИСПРАВЛЕННЫЙ градиент с единой логикой
                Button {
                    print("🎯 Timer button tapped")
                    togglePressed.toggle()
                    onTimerToggle()
                } label: {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 46))
                        .contentTransition(.symbolEffect(.replace, options: .speed(2.5)))
                        .foregroundStyle(habit.iconColor.adaptiveGradient(
                            for: colorScheme))
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
        }
        .frame(maxWidth: 300)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }
}
