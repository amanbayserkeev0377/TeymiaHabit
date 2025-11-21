import SwiftUI

struct HabitStatsListCard: View {
    
    let habit: Habit
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: HabitStatsViewModel
    
    init(habit: Habit, onTap: @escaping () -> Void) {
        self.habit = habit
        self.onTap = onTap
        self._viewModel = State(initialValue: HabitStatsViewModel(habit: habit))
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    HabitIconView(iconName: habit.iconName, color: habit.iconColor)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.title)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                        
                        Text("goal".localized(with: habit.formattedGoal))
                            .font(.footnote)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                StreaksView(viewModel: viewModel)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.mainRowBackground)
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: 10,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            viewModel.refresh()
        }
    }
}
