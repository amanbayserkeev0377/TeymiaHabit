import SwiftUI
import Charts

struct HabitLineChartCard: View {
    let habit: Habit
    let timeRange: OverviewTimeRange
    let onTap: () -> Void
    
    @State private var chartData: [LineChartDataPoint] = []
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    if let iconName = habit.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 20))
                            .foregroundStyle(habit.iconColor.color)
                            .frame(width: 24, height: 24)
                    }
                    
                    Text(habit.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Current period stats
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(currentPeriodProgress)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(habit.iconColor.color)
                        
                        Text(currentPeriodLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Line Chart
                Chart(chartData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Progress", dataPoint.completionRate)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [habit.iconColor.color, habit.iconColor.color.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    // Area under the line
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Progress", dataPoint.completionRate)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                habit.iconColor.color.opacity(0.3),
                                habit.iconColor.color.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 80)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatXAxisLabel(date: date, timeRange: timeRange))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...1.0)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .stroke(habit.iconColor.color.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            generateChartData()
        }
        .onChange(of: timeRange) { _, _ in
            generateChartData()
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatXAxisLabel(date: Date, timeRange: OverviewTimeRange) -> String {
        let formatter = DateFormatter()
        
        switch timeRange {
        case .week:
            formatter.dateFormat = "E"
            return String(formatter.string(from: date).prefix(1))
        case .month:
            let day = calendar.component(.day, from: date)
            return day % 5 == 0 ? "\(day)" : ""
        case .year:
            formatter.dateFormat = "MMM"
            return String(formatter.string(from: date).prefix(1))
        case .heatmap:
            return ""
        }
    }
    
    // MARK: - Data Generation
    
    private func generateChartData() {
        var data: [LineChartDataPoint] = []
        let today = Date()
        
        switch timeRange {
        case .week:
            // Last 7 days
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset - 6, to: today) else { continue }
                let completionRate = calculateCompletionRate(for: date)
                data.append(LineChartDataPoint(date: date, completionRate: completionRate))
            }
            
        case .month:
            // Last 30 days, but sample every 3 days for cleaner line
            for dayOffset in stride(from: 0, to: 30, by: 3) {
                guard let date = calendar.date(byAdding: .day, value: dayOffset - 29, to: today) else { continue }
                let completionRate = calculateCompletionRate(for: date)
                data.append(LineChartDataPoint(date: date, completionRate: completionRate))
            }
            
        case .year:
            // Last 12 months
            for monthOffset in 0..<12 {
                guard let date = calendar.date(byAdding: .month, value: monthOffset - 11, to: today) else { continue }
                let completionRate = calculateMonthlyCompletionRate(for: date)
                data.append(LineChartDataPoint(date: date, completionRate: completionRate))
            }
            
        case .heatmap:
            // Heatmap doesn't use line chart data
            break
        }
        
        chartData = data
    }
    
    private func calculateCompletionRate(for date: Date) -> Double {
        guard habit.isActiveOnDate(date) && date <= Date() else { return 0 }
        
        let progress = habit.progressForDate(date)
        let goal = habit.goal
        
        return min(1.0, Double(progress) / Double(goal))
    }
    
    private func calculateMonthlyCompletionRate(for monthDate: Date) -> Double {
        // Get all days in this month
        guard let range = calendar.range(of: .day, in: .month, for: monthDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
            return 0
        }
        
        var totalDays = 0
        var completedDays = 0
        
        for day in 1...range.count {
            guard let currentDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) else { continue }
            
            if habit.isActiveOnDate(currentDate) && currentDate <= Date() {
                totalDays += 1
                if habit.progressForDate(currentDate) >= habit.goal {
                    completedDays += 1
                }
            }
        }
        
        return totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0
    }
    
    // MARK: - Current Period Stats
    
    private var currentPeriodProgress: String {
        switch timeRange {
        case .week:
            let weekCompletedDays = (0..<7).filter { dayOffset in
                guard let date = calendar.date(byAdding: .day, value: dayOffset - 6, to: Date()) else { return false }
                return habit.isActiveOnDate(date) && habit.progressForDate(date) >= habit.goal
            }.count
            return "\(weekCompletedDays)/7"
            
        case .month:
            let monthCompletedDays = (0..<30).filter { dayOffset in
                guard let date = calendar.date(byAdding: .day, value: dayOffset - 29, to: Date()) else { return false }
                return habit.isActiveOnDate(date) && habit.progressForDate(date) >= habit.goal
            }.count
            return "\(monthCompletedDays)/30"
            
        case .year:
            let today = Date()
            let currentMonthRate = calculateMonthlyCompletionRate(for: today)
            return "\(Int(currentMonthRate * 100))%"
            
        case .heatmap:
            // Heatmap mode doesn't use this computed property
            return ""
        }
    }
    
    private var currentPeriodLabel: String {
        switch timeRange {
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Month"
        case .heatmap: return ""
        }
    }
}
