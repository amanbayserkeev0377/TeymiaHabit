import SwiftUI

struct ActionButtonsSection: View {
    let habit: Habit
    let date: Date
    let isTimerRunning: Bool
    
    var onReset: () -> Void
    var onTimerToggle: () -> Void
    var onManualEntry: () -> Void
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
        
    var body: some View {
        HStack(spacing: 18) {
            if habit.type == .time && isToday {
                resetButton
                playPauseButton
                manualEntryButton(icon: "clock.forward")
            } else {
                Spacer()
                resetButton
                manualEntryButton(icon: "keyboard.finger")
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Button Components
    
    @ViewBuilder
    private var resetButton: some View {
        Button {
            HapticManager.shared.play(.error)
            onReset()
        } label: {
            Image("undo")
                .resizable()
                .frame(width: 24, height: 24)
                .frame(minWidth: 44, minHeight: 44)
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var playPauseButton: some View {
        Button {
            HapticManager.shared.playImpact(.medium)
            onTimerToggle()
        } label: {
            Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 44))
                .contentTransition(.symbolEffect(.replace, options: .speed(1.0)))
                .frame(minWidth: 52, minHeight: 52)
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func manualEntryButton(icon: String) -> some View {
        Button {
            HapticManager.shared.playImpact(.medium)
            onManualEntry()
        } label: {
            Image(icon)
                .resizable()
                .frame(width: 24, height: 24)
                .frame(minWidth: 44, minHeight: 44)
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}
