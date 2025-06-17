import SwiftUI
import Charts

struct HabitLineChartCard: View {
    let habit: Habit
    let timeRange: OverviewTimeRange
    let onTap: () -> Void
    
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
                .padding(.horizontal, 16) // Отступы только для хедера
                
                // Line Chart - используем отдельные компоненты
                switch timeRange {
                case .week:
                    WeeklyHabitLineChart(habit: habit)
                        .padding(.horizontal, 16)
                        
                case .month:
                    MonthlyHabitLineChart(habit: habit)
                        .padding(.horizontal, 16)
                        
                case .year:
                    YearlyHabitLineChart(habit: habit)
                        .padding(.horizontal, 16)
                        
                case .heatmap:
                    // Heatmap не использует этот компонент
                    EmptyView()
                }
            }
            .padding(.horizontal, 0)  // Убираем горизонтальные отступы полностью
            .padding(.vertical, 12)   // Только вертикальные отступы
            // Фон убран для WMY режимов
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Current Period Stats
    
    private var currentPeriodProgress: String {
        switch timeRange {
        case .week:
            // Считаем последние 7 дней
            let today = Date()
            
            let weekCompletedDays = (0...6).filter { dayOffset in
                guard let date = calendar.date(byAdding: .day, value: dayOffset - 6, to: today) else { return false }
                return habit.isActiveOnDate(date) && habit.progressForDate(date) >= habit.goal
            }.count
            return "\(weekCompletedDays)/7"
            
        case .month:
            // Считаем последние 30 дней
            let today = Date()
            let monthCompletedDays = (0..<30).filter { dayOffset in
                guard let date = calendar.date(byAdding: .day, value: dayOffset - 29, to: today) else { return false }
                return habit.isActiveOnDate(date) && habit.progressForDate(date) >= habit.goal
            }.count
            return "\(monthCompletedDays)/30"
            
        case .year:
            // Считаем последние 12 месяцев (процент завершенных месяцев)
            let today = Date()
            let completedMonths = (0..<12).filter { monthOffset in
                guard let monthDate = calendar.date(byAdding: .month, value: monthOffset - 11, to: today) else { return false }
                return calculateMonthlyCompletionRate(for: monthDate) >= 0.8 // 80% дней в месяце
            }.count
            return "\(completedMonths)/12"
            
        case .heatmap:
            return ""
        }
    }
    
    private var currentPeriodLabel: String {
        switch timeRange {
        case .week: return "Last 7 Days"
        case .month: return "Last 30 Days"
        case .year: return "Last 12 Months"
        case .heatmap: return ""
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateMonthlyCompletionRate(for monthDate: Date) -> Double {
        // Получаем все дни в этом месяце
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
}
