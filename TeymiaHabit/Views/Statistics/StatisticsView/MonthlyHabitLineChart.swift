import SwiftUI
import Charts

struct MonthlyHabitLineChart: View {
    let habit: Habit
    
    @State private var chartData: [MonthlyChartDataPoint] = []
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    // ✅ УНИВЕРСАЛЬНОЕ РЕШЕНИЕ: динамическое равномерное распределение
    private var xAxisValues: [Date] {
        guard !chartData.isEmpty else { return [] }
        
        let totalDays = chartData.count // 30
        let targetLabels = 7 // Хотим 7 меток (6 столбцов)
        
        var values: [Date] = []
        
        // ✅ ВСЕГДА добавляем первый день
        values.append(chartData[0].date)
        
        // ✅ Вычисляем равномерные промежуточные точки
        if totalDays > 2 {
            let step = Double(totalDays - 1) / Double(targetLabels - 1)
            
            for i in 1..<(targetLabels - 1) {
                let index = Int(round(Double(i) * step))
                if index < totalDays && index > 0 {
                    values.append(chartData[index].date)
                }
            }
        }
        
        // ✅ ВСЕГДА добавляем последний день
        if totalDays > 1 {
            values.append(chartData[totalDays - 1].date)
        }
        
        // ✅ УБИРАЕМ дубликаты (на случай округления)
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
        
        // DEBUG: проверяем финальный результат
        let days = uniqueValues.map { calendar.component(.day, from: $0) }
        print("📍 DYNAMIC xAxisValues days: \(days)")
        
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
        // ✅ ДОБАВЛЯЕМ минимальные отступы для читабельности
        .chartXScale(range: .plotDimension(startPadding: 12, endPadding: 12))
        .chartXAxis {
            // ✅ ВОЗВРАЩАЕМ к принудительным значениям с улучшенной логикой
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
            generateChartData()
        }
    }
    
    private func generateChartData() {
        let today = Date()
        
        var data: [MonthlyChartDataPoint] = []
        
        // ✅ Генерируем 30 дней: от (сегодня - 29) до сегодня включительно
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -(29 - dayOffset), to: today) else { continue }
            
            // ✅ Нормализуем к полуночи для консистентности
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
        
        // ✅ РАСШИРЕННЫЙ DEBUG
        print("🔍 MonthlyHabitLineChart FIXED:")
        print("  Today: \(today.formatted(.dateTime.day().month()))")
        print("  Generated \(chartData.count) data points")
        print("  Chart from: \(chartData.first?.date.formatted(.dateTime.day().month()) ?? "?")")
        print("  Chart to: \(chartData.last?.date.formatted(.dateTime.day().month()) ?? "?")")
        
        // ✅ Проверяем что последний день = сегодня
        if let lastDate = chartData.last?.date {
            let isToday = calendar.isDate(lastDate, inSameDayAs: today)
            print("  ✅ Last day is today: \(isToday)")
            print("  Last day number: \(calendar.component(.day, from: lastDate))")
            print("  Today number: \(calendar.component(.day, from: today))")
        }
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
