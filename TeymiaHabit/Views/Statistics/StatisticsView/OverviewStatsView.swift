import SwiftUI

struct OverviewStatsView: View {
    let habits: [Habit]
    let timeRange: OverviewTimeRange
    
    @State private var statsData: MotivatingOverviewStats = MotivatingOverviewStats()
    @State private var showingInfoSheet = false
    @State private var selectedInfoCard: InfoCard? = nil
    @ObservedObject private var colorManager = AppColorManager.shared
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with info button
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(headerTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(headerSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Info button
                Button(action: { showingInfoSheet = true }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Stats Grid
            LazyVGrid(columns: gridColumns, spacing: 12) {
                StatCardWithInfo(
                    title: "Habits Done", 
                    value: "\(statsData.habitsCompleted)",
                    icon: "checkmark.rectangle.stack",
                    color: .green,
                    onInfoTap: { selectedInfoCard = .habitsDone }
                )
                
                StatCardWithInfo(
                    title: "Active Days", 
                    value: "\(statsData.activeDays)",
                    icon: "calendar.badge.checkmark",
                    color: colorManager.selectedColor.color,
                    onInfoTap: { selectedInfoCard = .activeDays }
                )
                
                StatCardWithInfo(
                    title: "Completion Rate", 
                    value: "\(Int(statsData.completionRate * 100))%",
                    icon: "chart.pie",
                    color: .blue,
                    onInfoTap: { selectedInfoCard = .completionRate }
                )
                
                StatCardWithInfo(
                    title: "Active Habits", 
                    value: "\(statsData.activeHabitsCount)",
                    icon: "list.bullet",
                    color: .orange,
                    onInfoTap: { selectedInfoCard = .activeHabits }
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
        .sheet(isPresented: $showingInfoSheet) {
            StatsInfoView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedInfoCard) { card in
            CardInfoView(card: card, timeRange: timeRange)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
        case .week: return "Last 7 Days"
        case .month: return "Last 30 Days"
        case .year: return "Last 12 Months"
        case .heatmap: return "Activity Overview"
        }
    }
    
    private var headerSubtitle: String {
        let formatter = DateFormatter()
        let today = Date()
        
        switch timeRange {
        case .week:
            let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: weekStart)
            let endString = formatter.string(from: today)
            return "\(startString) - \(endString)"
            
        case .month:
            let monthStart = calendar.date(byAdding: .day, value: -29, to: today) ?? today
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: monthStart)
            let endString = formatter.string(from: today)
            return "\(startString) - \(endString)"
            
        case .year:
            let yearStart = calendar.date(byAdding: .month, value: -11, to: today) ?? today
            formatter.dateFormat = "MMM yyyy"
            let startString = formatter.string(from: yearStart)
            let endString = formatter.string(from: today)
            return "\(startString) - \(endString)"
            
        case .heatmap:
            return "Past 365 days"
        }
    }
    
    // Removed unused streak properties since we replaced them with completion rate and active habits
    
    // MARK: - Stats Calculation
    
    private func calculateStats() {
        let now = Date()
        let dateRange = getDateRange(for: timeRange, from: now)
        
        let habitsCompleted = calculateHabitsCompleted(in: dateRange)
        let activeDays = calculateActiveDays(in: dateRange)
        let completionRate = calculateCompletionRate(in: dateRange)
        let activeHabitsCount = habits.filter { !$0.isArchived }.count
        
        statsData = MotivatingOverviewStats(
            habitsCompleted: habitsCompleted,
            activeDays: activeDays,
            completionRate: completionRate,
            activeHabitsCount: activeHabitsCount
        )
    }
    
    private func getDateRange(for timeRange: OverviewTimeRange, from date: Date) -> (start: Date, end: Date) {
        switch timeRange {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: date) ?? date
            return (start, date)
            
        case .month:
            let start = calendar.date(byAdding: .day, value: -29, to: date) ?? date
            return (start, date)
            
        case .year:
            let start = calendar.date(byAdding: .month, value: -11, to: date) ?? date
            return (start, date)
            
        case .heatmap:
            let start = calendar.date(byAdding: .day, value: -364, to: date) ?? date
            return (start, date)
        }
    }
    
    // MARK: - Individual Calculations
    
    private func calculateHabitsCompleted(in dateRange: (start: Date, end: Date)) -> Int {
        var completed = 0
        
        for habit in habits {
            var currentDate = dateRange.start
            while currentDate <= min(dateRange.end, Date()) {
                if habit.isActiveOnDate(currentDate) && habit.progressForDate(currentDate) >= habit.goal {
                    completed += 1
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        return completed
    }
    
    private func calculateActiveDays(in dateRange: (start: Date, end: Date)) -> Int {
        var activeDaysSet: Set<String> = []
        
        var currentDate = dateRange.start
        while currentDate <= min(dateRange.end, Date()) {
            
            let hasAnyProgress = habits.contains { habit in
                habit.isActiveOnDate(currentDate) && habit.progressForDate(currentDate) > 0
            }
            
            if hasAnyProgress {
                let dayKey = "\(calendar.component(.year, from: currentDate))-\(calendar.component(.month, from: currentDate))-\(calendar.component(.day, from: currentDate))"
                activeDaysSet.insert(dayKey)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return activeDaysSet.count
    }
    
    private func calculateCompletionRate(in dateRange: (start: Date, end: Date)) -> Double {
        var totalProgress = 0.0
        var totalPossibleProgress = 0.0
        
        for habit in habits.filter({ !$0.isArchived }) {
            var currentDate = dateRange.start
            while currentDate <= min(dateRange.end, Date()) {
                if habit.isActiveOnDate(currentDate) {
                    let progress = habit.progressForDate(currentDate)
                    let goal = habit.goal
                    
                    if goal > 0 {
                        totalProgress += min(Double(progress), Double(goal)) // Cap at goal to avoid over 100%
                        totalPossibleProgress += Double(goal)
                    }
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        return totalPossibleProgress > 0 ? totalProgress / totalPossibleProgress : 0.0
    }
}

// MARK: - Supporting Models

struct MotivatingOverviewStats {
    let habitsCompleted: Int          // Number of completed habits (any progress >= goal)
    let activeDays: Int               // Days with at least one action
    let completionRate: Double        // Average completion rate (0.0 to 1.0)
    let activeHabitsCount: Int        // Number of non-archived habits
    
    init(habitsCompleted: Int = 0, activeDays: Int = 0, completionRate: Double = 0.0, activeHabitsCount: Int = 0) {
        self.habitsCompleted = habitsCompleted
        self.activeDays = activeDays
        self.completionRate = completionRate
        self.activeHabitsCount = activeHabitsCount
    }
}

// MARK: - Info Models

enum InfoCard: String, Identifiable {
    case habitsDone = "habits_done"
    case activeDays = "active_days"
    case completionRate = "completion_rate"
    case activeHabits = "active_habits"
    
    var id: String { rawValue }
}

// MARK: - StatCard with Info

struct StatCardWithInfo: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let onInfoTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
                
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

// MARK: - Info Views

struct StatsInfoView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your statistics show your progress and achievements. Tap any card to learn more about what it measures.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Text("Remember: Every small step counts towards building lasting habits! 🌟")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding()
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
            }
            .navigationTitle("Statistics Help")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CardInfoView: View {
    let card: InfoCard
    let timeRange: OverviewTimeRange
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Card description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(cardTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(cardDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    // How it's calculated
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How it's calculated:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(calculationDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Example
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(exampleDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
            }
            .navigationTitle(cardTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var cardTitle: String {
        switch card {
        case .habitsDone: return "Habits Done"
        case .activeDays: return "Active Days"
        case .completionRate: return "Completion Rate"
        case .activeHabits: return "Active Habits"
        }
    }
    
    private var cardDescription: String {
        switch card {
        case .habitsDone:
            return "The total number of habits you've successfully completed during this period. A habit is considered 'done' when you reach or exceed your daily goal."
        case .activeDays:
            return "The number of days when you made progress on at least one habit. Even small progress counts as an active day!"
        case .completionRate:
            return "Your average completion percentage across all habits. This shows how well you're meeting your daily goals overall."
        case .activeHabits:
            return "The total number of habits you're currently tracking (not including archived habits). This gives you an overview of your current habit workload."
        }
    }
    
    private var calculationDescription: String {
        switch card {
        case .habitsDone:
            return "For each day in the period, we check each active habit. If your progress meets or exceeds the goal (e.g., 3 out of 3 glasses of water), it counts as one completed habit."
        case .activeDays:
            return "We count unique days where you made any progress on any habit. Partial progress (like 1 out of 3 glasses of water) still counts as an active day."
        case .completionRate:
            return "For each habit and each day, we calculate: (progress made / daily goal) × 100%. Then we average all these percentages across all habits and days in the period."
        case .activeHabits:
            return "We count all habits that are not archived. This includes habits that might not be active every day of the week, but are still part of your routine."
        }
    }
    
    private var exampleDescription: String {
        switch card {
        case .habitsDone:
            return "If you have 3 habits and complete 2 of them today, that adds 2 to your total. Over 7 days, you might complete 12 habits total."
        case .activeDays:
            return "If you work on habits Monday, Tuesday, Thursday, and Saturday, that's 4 active days, even if you didn't complete all goals each day."
        case .completionRate:
            return "If you have 2 habits: drink 3 glasses of water (you drank 2 = 67%) and read 30 minutes (you read 30 = 100%), your average completion rate is 83%."
        case .activeHabits:
            return "If you're tracking 'Morning Exercise', 'Read Books', and 'Drink Water', but archived 'Learn Spanish', your active habits count is 3."
        }
    }
}
