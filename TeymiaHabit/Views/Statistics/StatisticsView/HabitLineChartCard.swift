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
        Button(action: {
            HapticManager.shared.playSelection()
            onTap()
        }) {
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
                        .padding(.horizontal, 8)
                        
                case .month:
                    MonthlyHabitLineChart(habit: habit)
                        .padding(.horizontal, 8)
                        
                case .year:
                    YearlyHabitLineChart(habit: habit)
                        .padding(.horizontal, 8)
                        
                case .heatmap:
                    // Heatmap не использует этот компонент
                    EmptyView()
                }
            }
            .padding(.horizontal, 0)  // Убираем горизонтальные отступы полностью
            .padding(.vertical, 12)   // Только вертикальные отступы
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Current Period Stats
    
    private var currentPeriodProgress: String {
        switch timeRange {
        case .week:
            // Считаем последние 7 дней - возвращаем процент
            let today = Date()
            
            let weekCompletedDays = (0...6).filter { dayOffset in
                guard let date = calendar.date(byAdding: .day, value: dayOffset - 6, to: today) else { return false }
                return habit.isActiveOnDate(date) && habit.progressForDate(date) >= habit.goal
            }.count
            
            let percentage = Int((Double(weekCompletedDays) / 7.0) * 100)
            return "\(percentage)%"
            
        case .month:
            // Считаем последние 30 дней - возвращаем процент
            let today = Date()
            let monthCompletedDays = (0..<30).filter { dayOffset in
                guard let date = calendar.date(byAdding: .day, value: dayOffset - 29, to: today) else { return false }
                return habit.isActiveOnDate(date) && habit.progressForDate(date) >= habit.goal
            }.count
            
            let percentage = Int((Double(monthCompletedDays) / 30.0) * 100)
            return "\(percentage)%"
            
        case .year:
            // Считаем последние 365 дней - возвращаем процент
            let today = Date()
            
            var totalActiveDays = 0
            var completedDays = 0
            
            for dayOffset in 0..<365 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset - 364, to: today) else { continue }
                
                if habit.isActiveOnDate(date) && date <= Date() {
                    totalActiveDays += 1
                    if habit.progressForDate(date) >= habit.goal {
                        completedDays += 1
                    }
                }
            }
            
            let percentage = totalActiveDays > 0 ? Int((Double(completedDays) / Double(totalActiveDays)) * 100) : 0
            return "\(percentage)%"
            
        case .heatmap:
            return ""
        }
    }
    
    private var currentPeriodLabel: String {
        switch timeRange {
        case .week: return "last_7_days".localized
        case .month: return "last_30_days".localized
        case .year: return "last_12_months".localized
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
