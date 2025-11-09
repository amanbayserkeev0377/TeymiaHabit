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
                        baseSize: 26,
                        color: habit.iconColor,
                        colorScheme: colorScheme
                    )
                    .frame(width: 54, height: 54)
                    .background(
                        Circle()
                            .fill(habit.iconColor.color.gradient.opacity(0.15))
                    )
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.title)
                            .font(.body.weight(.medium))
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                        
                        Text("goal".localized(with: habit.formattedGoal))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                StreaksView(viewModel: viewModel)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                Color(.separator).opacity(0.5),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(
                        color: Color(.systemGray4).opacity(0.6),
                        radius: 4,
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
