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
                    universalIcon(
                        iconId: habit.iconName,
                        baseSize: 22,
                        color: habit.iconColor,
                        colorScheme: colorScheme
                    )
                    .frame(width: 46, height: 46)
                    .background(
                        Circle()
                            .fill(habit.iconColor.color.gradient.opacity(0.1))
                    )
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.title)
                            .fontWeight(.medium)
                            .fontDesign(.rounded)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                        
                        Text("goal".localized(with: habit.formattedGoal))
                            .font(.caption)
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
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(
                        color: .black.opacity(0.15),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            viewModel.refresh()
        }
    }
}
