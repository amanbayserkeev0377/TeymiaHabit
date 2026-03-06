import SwiftUI

struct ActionButtonsSection: View {
    let habit: Habit
    let date: Date
    let isToday: Bool
    let isTimerRunning: Bool
    
    var onReset: () -> Void
    var onTimerToggle: () -> Void
    var onManualCount: (Int) -> Void
    var onManualTime: (Int, Int) -> Void
    
    private enum Constants {
        static let buttonPadding: CGFloat = 10
        static let playButtonPadding: CGFloat = 12
        static let spacing: CGFloat = 18
    }
    
    var body: some View {
        HStack(spacing: Constants.spacing) {
            if habit.type == .time && isToday {
                resetButton
                playPauseButton
                manualEntryButton()
            } else {
                Spacer()
                resetButton
                manualEntryButton()
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
            Image(systemName: "arrow.uturn.backward")
                .font(.title2)
                .foregroundStyle(.primary)
                .padding(Constants.buttonPadding)
        }
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive(), in: .circle)
    }
    
    @ViewBuilder
    private var playPauseButton: some View {
        Button {
            HapticManager.shared.playImpact(.medium)
            onTimerToggle()
        } label: {
            Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                .font(.largeTitle)
                .contentTransition(.symbolEffect(.replace, options: .speed(1.3)))
                .foregroundStyle(.primary)
                .padding(Constants.playButtonPadding)
        }
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive(), in: .circle)
    }
    
    @ViewBuilder
    private func manualEntryButton() -> some View {
        CustomMenuView {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundStyle(.primary)
                .padding(Constants.buttonPadding)
        } content: {
            if habit.type == .count {
                CountInputPopover(
                    habit: habit,
                    date: Date(),
                    showQuickActions: false,
                    onConfirm: { val in onManualCount(val) }
                )
            } else {
                TimeInputPopover(
                    habit: habit,
                    date: Date(),
                    showQuickActions: false,
                    onConfirm: { h, m in onManualTime(h, m) }
                )
            }
        }
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive(), in: .circle)
    }
}
