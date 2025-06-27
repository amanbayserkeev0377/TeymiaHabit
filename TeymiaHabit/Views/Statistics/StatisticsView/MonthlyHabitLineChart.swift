import SwiftUI
import Charts

struct MonthlyHabitLineChart: View {
    let habit: Habit
    
    @State private var chartData: [MonthlyChartDataPoint] = []
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    // УНИВЕРСАЛЬНОЕ РЕШЕНИЕ: динамическое равномерное распределение
    private var xAxisValues: [Date] {
        guard !chartData.isEmpty else { return [] }
        
        let totalDays = chartData.count // 30
        let targetLabels = 7 // Хотим 7 меток (6 столбцов)
        
        var values: [Date] = []
        
        // ВСЕГДА добавляем первый день
        values.append(chartData[0].date)
        
        // Вычисляем равномерные промежуточные точки
        if totalDays > 2 {
            let step = Double(totalDays - 1) / Double(targetLabels - 1)
            
            for i in 1..<(targetLabels - 1) {
                let index = Int(round(Double(i) * step))
                if index < totalDays && index > 0 {
                    values.append(chartData[index].date)
                }
            }
        }
        
        // ВСЕГДА добавляем последний день
        if totalDays > 1 {
            values.append(chartData[totalDays - 1].date)
        }
        
        // УБИРАЕМ дубликаты (на случай округления)
        var uniqueValues: [Date] = []
        for date in values {
            let dayNumber = calendar.component(.day, from: date)
            let isDuplicate = uniqueValues.contains { existingDate in
                calendar.component(.day, from: existingDate) == dayNumber
            }
            if !isDuplicate {
                uniqueValues.append(date)
            }
        }
        
        return uniqueValues
    }
    
    var body: some View {
        Chart(chartData) { dataPoint in
            LineMark(
                x: .value("Day", dataPoint.date, unit: .day),
                y: .value("Progress", dataPoint.completionRate)
            )
            .foregroundStyle(habit.iconColor.color)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.monotone)
            
            AreaMark(
                x: .value("Day", dataPoint.date, unit: .day),
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
        .chartXScale(range: .plotDimension(startPadding: 12, endPadding: 12))
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.caption2)
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
        var data: [MonthlyChartDataPoint] = []
        
        // Генерируем 30 дней: от (сегодня - 29) до сегодня включительно
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -(29 - dayOffset), to: today) else { continue }
            
            // Нормализуем к полуночи для консистентности
            let normalizedDate = calendar.startOfDay(for: date)
            
            let dayName = formatDayName(date: normalizedDate)
            let completionRate = calculateCompletionRate(for: date) // Используем оригинальную дату для расчетов
            
            data.append(MonthlyChartDataPoint(
                dayName: dayName,
                date: normalizedDate,
                completionRate: completionRate
            ))
        }
        
        chartData = data
    }
    
    private func formatDayName(date: Date) -> String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }
    
    private func calculateCompletionRate(for date: Date) -> Double {
        guard habit.isActiveOnDate(date) && date <= Date() else { return 0 }
        
        let progress = habit.progressForDate(date)
        let goal = habit.goal
        
        let rate = goal > 0 ? Double(progress) / Double(goal) : 0
        return min(1.0, rate)
    }
}
