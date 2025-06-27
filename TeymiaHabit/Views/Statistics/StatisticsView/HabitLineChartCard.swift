import SwiftUI
import Charts

struct HabitLineChartCard: View {
    let habit: Habit
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
                .padding(.horizontal, 16)
                
                // Line Chart - только W/M (Y обрабатывается отдельно)
                switch timeRange {
                case .week:
                    WeeklyHabitLineChart(habit: habit)
                        .padding(.horizontal, 8)
                        
                case .month:
                    MonthlyHabitLineChart(habit: habit)
                        .padding(.horizontal, 8)
                        
                case .year:
                    // Этот case не должен попадать сюда - Y обрабатывается в StatisticsView
                    EmptyView()
                }
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - ИСПРАВЛЕННЫЙ Current Period Stats (показывает средний %, не только 100% дни)
    
    private var currentPeriodProgress: String {
        switch timeRange {
        case .week:
            return calculateAverageCompletionRate(days: 7, startOffset: -6)
            
        case .month:
            return calculateAverageCompletionRate(days: 30, startOffset: -29)
            
        case .year:
            return calculateAverageCompletionRate(days: 365, startOffset: -364)
        }
    }
    
    private var currentPeriodLabel: String {
        switch timeRange {
        case .week: return "last_7_days".localized
        case .month: return "last_30_days".localized
        case .year: return "last_12_months".localized
        }
    }
    
    // MARK: - НОВЫЙ Helper Method - правильный расчёт среднего процента
    
    private func calculateAverageCompletionRate(days: Int, startOffset: Int) -> String {
        let today = Date()
        var totalProgress = 0.0
        var totalDays = 0
        
        // Проходим по всем дням в периоде
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: startOffset + dayOffset, to: today) else {
                continue
            }
            
            // Учитываем только активные дни привычки
            if habit.isActiveOnDate(date) && date <= Date() {
                let progress = habit.progressForDate(date)
                let goal = habit.goal
                
                if goal > 0 {
                    // Рассчитываем процент выполнения (ограничиваем до 100%)
                    let dayCompletionRate = min(Double(progress) / Double(goal), 1.0)
                    totalProgress += dayCompletionRate
                    totalDays += 1
                }
            }
        }
        
        // Возвращаем средний процент выполнения
        let averagePercent = totalDays > 0 ? Int((totalProgress / Double(totalDays)) * 100) : 0
        return "\(averagePercent)%"
    }
}
