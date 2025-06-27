import SwiftUI
import Charts

struct WeeklyHabitLineChart: View {
    let habit: Habit
    
    @State private var chartData: [WeeklyChartDataPoint] = []
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        Chart(chartData) { dataPoint in
            LineMark(
                x: .value("Day", dataPoint.dayName),
                y: .value("Progress", dataPoint.completionRate)
            )
            .foregroundStyle(habit.iconColor.color)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.monotone)
            
            AreaMark(
                x: .value("Day", dataPoint.dayName),
                y: .value("Progress", dataPoint.completionRate)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        habit.iconColor.color.opacity(0.5),
                        habit.iconColor.color.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.monotone)
        }
        .frame(height: 140)
        .chartYScale(domain: 0...1.0)
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel {
                    if let dayName = value.as(String.self) {
                        Text(dayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            // 🔧 ИСПРАВЛЕНИЕ: всегда обновляем данные при появлении
            generateChartData()
        }
        .onChange(of: habit.completions?.count) { _, _ in
            // 🔧 НОВОЕ: реактивное обновление при изменении данных
            generateChartData()
        }
        .onChange(of: habit.goal) { _, _ in
            // 🔧 НОВОЕ: обновляем при изменении цели
            generateChartData()
        }
    }
    
    private func generateChartData() {
        let today = Date()
        var data: [WeeklyChartDataPoint] = []
        
        let startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        
        for dayOffset in 0...6 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let dayName = calendar.shortWeekdaySymbols[weekdayIndex]
            let completionRate = calculateCompletionRate(for: date)
            
            data.append(WeeklyChartDataPoint(
                dayName: dayName,
                date: date,
                completionRate: completionRate
            ))
        }
        
        chartData = data
    }
    
    private func calculateCompletionRate(for date: Date) -> Double {
        guard habit.isActiveOnDate(date) && date <= Date() else { return 0 }
        
        let progress = habit.progressForDate(date)
        let goal = habit.goal
        
        let rate = goal > 0 ? Double(progress) / Double(goal) : 0
        return min(1.0, max(0.0, rate)) // Гарантируем 0-100%
    }
}
