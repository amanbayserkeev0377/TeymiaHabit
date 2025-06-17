import SwiftUI

struct OverviewStatsView: View {
    let habits: [Habit]
    let timeRange: OverviewTimeRange
    
    @State private var statsData: OverviewStats = OverviewStats()
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(headerTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Stats Grid
            LazyVGrid(columns: gridColumns, spacing: 12) {
                StatCard(
                    title: "Total Completions", 
                    value: "\(statsData.totalCompletions)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Completion Rate", 
                    value: "\(Int(statsData.completionRate * 100))%",
                    icon: "chart.pie.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Active Habits", 
                    value: "\(statsData.activeHabits)",
                    icon: "list.bullet.circle.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Best Streak", 
                    value: "\(statsData.bestStreak) days",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
        }
        .onAppear {
            calculateStats()
        }
        .onChange(of: timeRange) { _, _ in
            calculateStats()
        }
        .onChange(of: habits.count) { _, _ in
            calculateStats()
        }
    }
    
    // MARK: - Computed Properties
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }
    
    private var headerTitle: String {
        switch timeRange {
        case .week:
            return "This Week Overview"
        case .month:
            return "This Month Overview"
        case .year:
            return "This Year Overview"
        case .heatmap:
            return "Activity Overview"
        }
    }
    
    private var headerSubtitle: String {
        let formatter = DateFormatter()
        let today = Date()
        
        switch timeRange {
        case .week:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
            let weekEnd = calendar.dateInterval(of: .weekOfYear, for: today)?.end ?? today
            
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: weekStart)
            let endString = formatter.string(from: weekEnd)
            return "\(startString) - \(endString)"
            
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: today)
            
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: today)
            
        case .heatmap:
            return "Past 365 days"
        }
    }
    
    // MARK: - Stats Calculation
    
    private func calculateStats() {
        let now = Date()
        let dateRange = getDateRange(for: timeRange, from: now)
        
        var totalCompletions = 0
        var totalPossibleCompletions = 0
        var activeHabitsCount = 0
        var allStreaks: [Int] = []
        
        for habit in habits {
            let habitStats = calculateHabitStats(habit, in: dateRange)
            
            totalCompletions += habitStats.completions
            totalPossibleCompletions += habitStats.possibleCompletions
            
            if habitStats.completions > 0 {
                activeHabitsCount += 1
            }
            
            allStreaks.append(habitStats.bestStreak)
        }
        
        let completionRate = totalPossibleCompletions > 0 ? 
            Double(totalCompletions) / Double(totalPossibleCompletions) : 0.0
        
        let bestStreak = allStreaks.max() ?? 0
        
        statsData = OverviewStats(
            totalCompletions: totalCompletions,
            completionRate: completionRate,
            activeHabits: activeHabitsCount,
            bestStreak: bestStreak
        )
    }
    
    private func getDateRange(for timeRange: OverviewTimeRange, from date: Date) -> (start: Date, end: Date) {
        switch timeRange {
        case .week:
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) ??
                DateInterval(start: date, end: date)
            return (weekInterval.start, weekInterval.end)
            
        case .month:
            let monthInterval = calendar.dateInterval(of: .month, for: date) ??
                DateInterval(start: date, end: date)
            return (monthInterval.start, monthInterval.end)
            
        case .year:
            let yearInterval = calendar.dateInterval(of: .year, for: date) ??
                DateInterval(start: date, end: date)
            return (yearInterval.start, yearInterval.end)
            
        case .heatmap:
            let start = calendar.date(byAdding: .day, value: -365, to: date) ?? date
            return (start, date)
        }
    }
    
    private func calculateHabitStats(_ habit: Habit, in dateRange: (start: Date, end: Date)) -> HabitStatsInRange {
        var completions = 0
        var possibleCompletions = 0
        var currentStreak = 0
        var bestStreak = 0
        var tempStreak = 0
        
        var currentDate = dateRange.start
        let endDate = min(dateRange.end, Date()) // Don't count future dates
        
        while currentDate <= endDate {
            if habit.isActiveOnDate(currentDate) {
                possibleCompletions += 1
                
                let isCompleted = isHabitCompletedOnDate(habit, date: currentDate)
                
                if isCompleted {
                    completions += 1
                    tempStreak += 1
                    bestStreak = max(bestStreak, tempStreak)
                } else {
                    tempStreak = 0
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Current streak calculation (from the end)
        currentDate = endDate
        while currentDate >= dateRange.start && habit.isActiveOnDate(currentDate) {
            if isHabitCompletedOnDate(habit, date: currentDate) {
                currentStreak += 1
            } else {
                break
            }
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return HabitStatsInRange(
            completions: completions,
            possibleCompletions: possibleCompletions,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
    }
    
    private func isHabitCompletedOnDate(_ habit: Habit, date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        guard let completions = habit.completions else { return false }
        
        let dayCompletions = completions.filter { completion in
            completion.date >= dayStart && completion.date < dayEnd
        }
        
        let totalValue = dayCompletions.reduce(0) { $0 + $1.value }
        return totalValue >= habit.goal
    }
}

// MARK: - Supporting Models

struct OverviewStats {
    let totalCompletions: Int
    let completionRate: Double // 0.0 to 1.0
    let activeHabits: Int
    let bestStreak: Int
    
    init(totalCompletions: Int = 0, completionRate: Double = 0.0, activeHabits: Int = 0, bestStreak: Int = 0) {
        self.totalCompletions = totalCompletions
        self.completionRate = completionRate
        self.activeHabits = activeHabits
        self.bestStreak = bestStreak
    }
}

struct HabitStatsInRange {
    let completions: Int
    let possibleCompletions: Int
    let currentStreak: Int
    let bestStreak: Int
}

// MARK: - StatCard Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        }
    }
}
