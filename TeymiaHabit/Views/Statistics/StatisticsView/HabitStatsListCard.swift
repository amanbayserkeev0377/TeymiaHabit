import SwiftUI

struct HabitStatsListCard: View {
    let habit: Habit
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme

    // Create individual ViewModel for each habit
    @State private var viewModel: HabitStatsViewModel
    
    // Initialize with habit-specific ViewModel
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
            VStack(alignment: .leading, spacing: 16) {
                // Header with habit info
                HStack {
                    // Habit icon
                       universalIcon(
                           iconId: habit.iconName,
                           baseSize: 28,
                           color: habit.iconColor,
                           colorScheme: colorScheme
                       )
                       .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text("goal".localized(with: habit.formattedGoal))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Individual StreaksView for this habit
                StreaksView(viewModel: viewModel)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
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
            // Refresh stats when card appears
            viewModel.refresh()
        }
    }
}
