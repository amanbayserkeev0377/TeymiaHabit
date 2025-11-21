import SwiftUI

struct OverviewStatsView: View {
    let habits: [Habit]
    
    @State private var statsData: MotivatingOverviewStats = MotivatingOverviewStats()
    @State private var selectedInfoCard: InfoCard? = nil
    @ObservedObject private var colorManager = AppColorManager.shared
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        HStack(spacing: 16) {
            StatCardInteractive(
                title: "active_habits".localized,
                value: "\(activeHabitsCount)"
            )
            StatCardInteractive(
                title: "overall_completion".localized,
                value: "\(Int(overallCompletionRate * 100))%"
            )
            StatCardInteractive(
                title: "completed_total".localized,
                value: "\(totalCompletedHabits)"
            )
        }
        .padding(16)
    }
    
    // MARK: - Computed Properties
    
    private var totalCompletedHabits: Int {
        habits.reduce(0) { total, habit in
            total + (habit.completions?.filter { $0.value >= habit.goal }.count ?? 0)
        }
    }
    
    private var overallCompletionRate: Double {
        var totalProgress = 0.0
        var totalPossibleProgress = 0.0
        
        for habit in habits.filter({ !$0.isArchived }) {
            guard let completions = habit.completions else { continue }
            
            for completion in completions {
                if habit.isActiveOnDate(completion.date) {
                    let progress = completion.value
                    let goal = habit.goal
                    
                    if goal > 0 {
                        totalProgress += min(Double(progress), Double(goal))
                        totalPossibleProgress += Double(goal)
                    }
                }
            }
        }
        
        return totalPossibleProgress > 0 ? totalProgress / totalPossibleProgress : 0.0
    }
    
    private var activeHabitsCount: Int {
        habits.filter { !$0.isArchived }.count
    }
}

// MARK: - Supporting Models

struct MotivatingOverviewStats {
    let habitsCompleted: Int          // Number of completed habits (any progress >= goal)
    let completionRate: Double        // Average completion rate (0.0 to 1.0)
    let activeHabitsCount: Int        // Number of non-archived habits
    
    init(habitsCompleted: Int = 0, completionRate: Double = 0.0, activeHabitsCount: Int = 0) {
        self.habitsCompleted = habitsCompleted
        self.completionRate = completionRate
        self.activeHabitsCount = activeHabitsCount
    }
}

// MARK: - Info Models

enum InfoCard: String, Identifiable {
    case habitsDone = "overall_completion"
    case completionRate = "completed_total"
    case activeHabits = "active_habits"
    
    var id: String { rawValue }
}

// MARK: - StatCardInteractive

struct StatCardInteractive: View {
    let title: String
    let value: String
    
    init(
        title: String,
        value: String,
    ) {
        self.title = title
        self.value = value
    }
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.footnote)
                .fontDesign(.rounded)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        }
    }
}
