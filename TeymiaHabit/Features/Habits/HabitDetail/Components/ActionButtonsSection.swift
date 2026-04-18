import SwiftUI

struct ActionButtonsSection: View {
    @Environment(HabitService.self) private var habitService
    
    let habit: Habit
    let date: Date
    let isToday: Bool
    let isTimerRunning: Bool
    
    var onReset: () -> Void
    var onTimerToggle: () -> Void
    
    @State private var isShowingPopover = false
    
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
                manualEntryButton
            } else {
                Spacer()
                resetButton
                manualEntryButton
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Button Components
    
    @ViewBuilder
    private var resetButton: some View {
        Button {
            onReset()
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(.title2)
                .foregroundStyle(.primary)
                .padding(Constants.buttonPadding)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
    }
    
    @ViewBuilder
    private var playPauseButton: some View {
        Button {
            onTimerToggle()
        } label: {
            Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                .font(.largeTitle)
                .contentTransition(.symbolEffect(.replace, options: .speed(1.3)))
                .foregroundStyle(.primary)
                .padding(Constants.playButtonPadding)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
    }
    
    @ViewBuilder
    private var manualEntryButton: some View {
        Button {
            isShowingPopover = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundStyle(.primary)
                .padding(Constants.buttonPadding)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .popover(isPresented: $isShowingPopover) {
            DayProgressPopover(habit: habit, date: date)
                .environment(habitService)
                .presentationCompactAdaptation(.popover)
        }
    }
}
