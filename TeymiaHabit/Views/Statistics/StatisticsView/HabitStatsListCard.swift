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
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Individual StreaksView for this habit
                StreaksView(viewModel: viewModel)
                    .padding(.horizontal, 8)
                
                // Recent progress indicator
                HStack {
                    recentProgressView
                    
                    Spacer()
                    
                    // Last completed info
                    if let lastCompletedDate = lastCompletedDate {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Last completed")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            Text(formatRelativeDate(lastCompletedDate))
                                .font(.caption)
                                .foregroundStyle(habit.iconColor.color)
                        }
                    }
                }
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
    
    // MARK: - Recent Progress View
    
    @ViewBuilder
    private var recentProgressView: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { dayOffset in
                let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                let isActive = habit.isActiveOnDate(date)
                let isCompleted = habit.isCompletedForDate(date)
                
                Circle()
                    .fill(progressColor(isActive: isActive, isCompleted: isCompleted))
                    .frame(width: 8, height: 8)
            }
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
