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
                if habit.type == .time && isToday {
                    // 3 buttons for time habits on today
                    resetButton
                    playPauseButton
                    manualEntryButton(icon: "clock")
                } else {
                    // 2 buttons for count habits or past dates - centered
                    Spacer()
                    resetButton
                    manualEntryButton(icon: "keyboard")
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
    }
    
    // MARK: - Button Components
    
    @ViewBuilder
    private var resetButton: some View {
        Button {
            resetPressed.toggle()
            onReset()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 24, weight: .semibold))
                .withHabitGradient(habit, colorScheme: colorScheme)
                .frame(minWidth: 52, minHeight: 52)
                .symbolEffect(.rotate, options: .speed(6.0), value: resetPressed)
        }
        .errorHaptic(trigger: resetPressed)
    }
    
    @ViewBuilder
    private var playPauseButton: some View {
        Button {
            print("🎯 Timer button tapped")
            togglePressed.toggle()
            onTimerToggle()
        } label: {
            Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 46))
                .contentTransition(.symbolEffect(.replace, options: .speed(1.0)))
                .withHabitGradient(habit, colorScheme: colorScheme)
                .frame(minWidth: 52, minHeight: 52)
        }
        .hapticFeedback(.impact(weight: .medium), trigger: togglePressed)
    }
    
    @ViewBuilder
    private func manualEntryButton(icon: String) -> some View {
        Button {
            manualEntryPressed.toggle()
            onManualEntry()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .withHabitGradient(habit, colorScheme: colorScheme)
                .frame(minWidth: 52, minHeight: 52)
        }
        .hapticFeedback(.impact(weight: .medium), trigger: manualEntryPressed)
    }
}
