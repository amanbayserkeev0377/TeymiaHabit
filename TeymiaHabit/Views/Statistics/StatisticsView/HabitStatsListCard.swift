import SwiftUI

struct HabitStatsListCard: View {
    let habit: Habit
    let onTap: () -> Void
    
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
                    if let iconName = habit.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(habit.iconColor.color)
                            .frame(width: 32, height: 32)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text(habit.formattedGoal)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Navigate indicator
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(habit.iconColor.color)
                }
                
                // Individual StreaksView for this habit
                StreaksView(viewModel: viewModel)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Refresh stats when card appears
            viewModel.refresh()
        }
    }
    
    // MARK: - Helper Methods
    
    private func progressColor(isActive: Bool, isCompleted: Bool) -> Color {
        if !isActive {
            return Color.gray.opacity(0.2)
        } else if isCompleted {
            return habit.iconColor.color
        } else {
            return Color.gray.opacity(0.4)
        }
    }
    
    private var lastCompletedDate: Date? {
        guard let completions = habit.completions else { return nil }
        
        return completions
            .filter { $0.value >= habit.goal }
            .map { $0.date }
            .max()
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            return "\(days) days ago"
        }
    }
}
