import SwiftUI

struct HabitProgressView: View {
    let viewModel: HabitDetailViewModel
    let habit: Habit
    
    var body: some View {
            HStack {
                Spacer()
                decrementButton
                Spacer()
                ProgressRing(
                    progress: viewModel.completionPercentage,
                    currentValue: "\(viewModel.currentProgress)",
                    isCompleted: viewModel.isAlreadyCompleted,
                    isExceeded: viewModel.currentProgress > habit.goal,
                    habit: habit,
                    size: 180
                )
                Spacer()
                incrementButton
                Spacer()
            }
        .onChange(of: viewModel.currentProgress) { oldValue, newValue in
            viewModel.checkGoalProgress(newValue)
        }
    }
    
    private var decrementButton: some View {
        Button {
            HapticManager.shared.playSelection()
            viewModel.decrementProgress()
        } label: {
            Image(systemName: "minus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.primary)
                .frame(width: 48, height: 48)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .disabled(viewModel.currentProgress <= 0)
    }

    private var incrementButton: some View {
        Button {
            HapticManager.shared.playSelection()
            viewModel.incrementProgress()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.primary)
                .frame(width: 48, height: 48)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
    }
}
