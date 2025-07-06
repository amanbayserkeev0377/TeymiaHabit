import SwiftUI
import Charts

/// Максимально упрощенный и быстрый годовой график
struct YearlyHabitLineChart: View {
    let habit: Habit
    
    @State private var chartData: [ChartDataPoint] = []
    
    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    var body: some View {
        Chart(chartData) { dataPoint in
            LineMark(
                x: .value("Month", dataPoint.date, unit: .month),
                y: .value("Progress", dataPoint.completionPercentage)
            )
            .foregroundStyle(habit.iconColor.color)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.monotone)
            
            AreaMark(
                x: .value("Month", dataPoint.date, unit: .month),
                y: .value("Progress", dataPoint.completionPercentage)
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
            AxisMarks(values: .stride(by: .month)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(monthFormatter.string(from: date).prefix(1).uppercased())
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
            generateChartData()
        }
        .onChange(of: habit.completions?.count) { _, _ in
            generateChartData()
        }
        .onChange(of: habit.goal) { _, _ in
            generateChartData()
        }
    }
    
    // MARK: - 🔥 УПРОЩЕННАЯ но эффективная генерация данных
    
    private func generateSimpleChartData() -> [ChartDataPoint] {
        let today = Date()
        var data: [ChartDataPoint] = []
        
        // Простой подход: считаем статистику по месяцам напрямую
        for monthOffset in 0..<12 {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: today) else {
                continue
            }
            
            let completionRate = calculateMonthCompletionRate(for: monthDate)
            
            data.append(ChartDataPoint(
                date: monthDate,
                value: Int(completionRate * 100),
                goal: 100,
                habit: habit
            ))
        }
        
        return data.reversed()
    }
    
    private func generateChartData() {
        chartData = generateSimpleChartData()
    }
    
    private func calculateMonthCompletionRate(for monthDate: Date) -> Double {
        // Получаем диапазон дней в месяце
        guard let range = calendar.range(of: .day, in: .month, for: monthDate),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
            return 0
        }
        
        var totalProgress = 0.0
        var activeDaysCount = 0
        
        // Проходим по всем дням месяца
        for day in 1...range.count {
            guard let currentDate = calendar.date(byAdding: .day, value: day - 1, to: firstDay) else {
                continue
            }
            
            // Проверяем только активные дни и не в будущем
            if habit.isActiveOnDate(currentDate) &&
                currentDate >= habit.startDate &&
                currentDate <= Date() {
                
                activeDaysCount += 1
                
                // Считаем прогресс для этого дня
                let progress = habit.progressForDate(currentDate)
                let goal = habit.goal
                
                if goal > 0 {
                    let dayRate = min(Double(progress) / Double(goal), 1.0)
                    totalProgress += dayRate
                }
            }
        }
        
        return activeDaysCount > 0 ? totalProgress / Double(activeDaysCount) : 0
    }
}
