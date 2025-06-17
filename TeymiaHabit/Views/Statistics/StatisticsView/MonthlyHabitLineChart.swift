import SwiftUI
import Charts

struct MonthlyHabitLineChart: View {
    let habit: Habit
    
    @State private var chartData: [MonthlyChartDataPoint] = []
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    // Вычисляем конкретные даты для оси X
    private var xAxisValues: [Date] {
        guard !chartData.isEmpty else { return [] }
        
        var dates: [Date] = []
        
        // НОВЫЙ ПОДХОД: показываем каждые 3 дня, но ГАРАНТИРУЕМ последний день
        for (index, dataPoint) in chartData.enumerated() {
            let isEveryThirdDay = index % 3 == 0
            let isLastDay = index == chartData.count - 1
            let isSecondToLastDay = index == chartData.count - 2 // Добавляем предпоследний для контекста
            
            if isEveryThirdDay || isLastDay || isSecondToLastDay {
                dates.append(dataPoint.date)
            }
        }
        
        // DEBUG: проверяем какие даты мы передаем в AxisMarks
        print("📍 xAxisValues: \(dates.map { calendar.component(.day, from: $0) })")
        
        return dates
    }
    
    // Принудительно задаем диапазон X-оси от первого до последнего дня
    private var xAxisDomain: ClosedRange<Date> {
        guard let firstDate = chartData.first?.date,
              let lastDate = chartData.last?.date else {
            return Date()...Date()
        }
        return firstDate...lastDate
    }
    
    var body: some View {
        Chart(chartData) { dataPoint in
            // Возвращаем LineMark как изначально задумано
            LineMark(
                x: .value("Day", dataPoint.date, unit: .day),
                y: .value("Progress", dataPoint.completionRate)
            )
            .foregroundStyle(habit.iconColor.color)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Day", dataPoint.date, unit: .day),
                y: .value("Progress", dataPoint.completionRate)
            )
            .foregroundStyle(habit.iconColor.color.opacity(0.2))
        }
        .frame(height: 140)
        .padding(.trailing, 8) // Добавляем padding справа для последней метки
        .chartXAxis {
            // ПРОСТОЕ РЕШЕНИЕ: пусть Charts сам решает что показывать
            AxisMarks(values: .stride(by: .day, count: 3)) { value in
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
        .chartYScale(domain: 0...1.0)
        .onAppear {
            generateChartData()
        }
    }
    
    // MARK: - Data Generation
    
    private func generateChartData() {
        let today = Date()
        var data: [MonthlyChartDataPoint] = []
        
        // ИСПРАВЛЯЕМ: показываем последние 30 дней правильно!
        // От 29 дней назад до СЕГОДНЯ (включительно)
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset - 29, to: today) else { continue }
            
            let dayName = formatDayName(date: date)
            let completionRate = calculateCompletionRate(for: date)
            
            data.append(MonthlyChartDataPoint(
                dayName: dayName,
                date: date,
                completionRate: completionRate
            ))
        }
        
        chartData = data
        
        // DEBUG - проверяем правильность дат
        print("🔍 MonthlyHabitLineChart: Generated \(chartData.count) data points")
        print("  From: \(chartData.first?.date.formatted(.dateTime.day().month()) ?? "?")")
        print("  To: \(chartData.last?.date.formatted(.dateTime.day().month()) ?? "?")")
        print("  Today should be last: \(today.formatted(.dateTime.day().month()))")
    }
    
    private func formatDayName(date: Date) -> String {
        let day = calendar.component(.day, from: date)
        return "\(day)" // Показываем день месяца
    }
    
    private func calculateCompletionRate(for date: Date) -> Double {
        guard habit.isActiveOnDate(date) && date <= Date() else { return 0 }
        
        let progress = habit.progressForDate(date)
        let goal = habit.goal
        
        // Ограничиваем максимумом 100% как в требованиях
        let rate = goal > 0 ? Double(progress) / Double(goal) : 0
        return min(1.0, rate)
    }
    
    private func barColor(for dataPoint: MonthlyChartDataPoint) -> Color {
        let date = dataPoint.date
        let completionRate = dataPoint.completionRate
        
        // Future dates or inactive days
        if !habit.isActiveOnDate(date) || date > Date() {
            return Color.gray.opacity(0.2)
        }
        
        // No progress
        if completionRate == 0 {
            return Color.gray.opacity(0.3)
        }
        
        // Completed (100%)
        if completionRate >= 1.0 {
            return Color(red: 0.2, green: 0.8, blue: 0.4) // Success green
        } else {
            // Partial progress - use habit color with opacity based on completion
            return habit.iconColor.color.opacity(0.4 + (completionRate * 0.6))
        }
    }
}

// Data model находится в LineChartModels.swift
