import SwiftUI
import Charts

struct YearlyHabitLineChart: View {
    let habit: Habit
    
    @State private var chartData: [YearlyChartDataPoint] = []
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    var body: some View {
        Chart(chartData) { dataPoint in
            LineMark(
                x: .value("Month", dataPoint.date, unit: .month), // Используем Date вместо String!
                y: .value("Progress", dataPoint.completionRate)
            )
            .foregroundStyle(habit.iconColor.color)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Month", dataPoint.date, unit: .month), // Используем Date вместо String!
                y: .value("Progress", dataPoint.completionRate)
            )
            .foregroundStyle(habit.iconColor.color.opacity(0.2))
        }
        .frame(height: 140)
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
        .chartYScale(domain: 0...1.0)
        .onAppear {
            generateChartData()
        }
    }
    
    // MARK: - Data Generation
    
    private func generateChartData() {
        let today = Date()
        var data: [YearlyChartDataPoint] = []
        
        // ВСЕГДА генерируем ровно 12 месяцев, независимо от данных
        for monthOffset in 0..<12 {
            // Идем назад от текущего месяца: 0 = текущий, 1 = прошлый, и т.д.
            guard let date = calendar.date(byAdding: .month, value: -monthOffset, to: today) else { 
                // Если не удалось создать дату, добавляем пустую точку
                let fallbackDate = calendar.date(byAdding: .month, value: -monthOffset, to: today) ?? today
                data.append(YearlyChartDataPoint(
                    monthName: "?",
                    date: fallbackDate,
                    completionRate: 0.0
                ))
                continue
            }
            
            let monthName = formatMonthName(date: date)
            let completionRate = calculateMonthlyCompletionRate(for: date)
            
            data.append(YearlyChartDataPoint(
                monthName: monthName,
                date: date,
                completionRate: completionRate
            ))
        }
        
        // Переворачиваем массив, чтобы самый старый месяц был слева, текущий справа
        chartData = data.reversed()
        
        // DEBUG: Проверяем количество точек
        print("🔍 YearlyHabitLineChart: Generated \(chartData.count) data points")
        for (index, point) in chartData.enumerated() {
            print("  \(index): \(point.monthName) - \(point.date)")
        }
    }
    
    private func formatMonthName(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let monthName = formatter.string(from: date)
        
        // Добавляем год если нужно различить месяцы
        let currentYear = calendar.component(.year, from: Date())
        let monthYear = calendar.component(.year, from: date)
        
        if monthYear != currentYear {
            // Для прошлого года добавляем последние 2 цифры года
            return "\(String(monthName.prefix(1)))\(String(monthYear).suffix(2))"
        } else {
            // Для текущего года только первая буква
            return String(monthName.prefix(1)).uppercased()
        }
    }
    
    private func calculateMonthlyCompletionRate(for monthDate: Date) -> Double {
        // Получаем все дни в этом месяце
        guard let range = calendar.range(of: .day, in: .month, for: monthDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
            print("⚠️ Failed to get month range for \(monthDate)")
            return 0
        }
        
        var totalDays = 0
        var completedDays = 0
        
        for day in 1...range.count {
            guard let currentDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) else { continue }
            
            // Проверяем что дата в пределах привычки и не в будущем
            if habit.isActiveOnDate(currentDate) && 
               currentDate >= habit.startDate && 
               currentDate <= Date() {
                totalDays += 1
                if habit.progressForDate(currentDate) >= habit.goal {
                    completedDays += 1
                }
            }
        }
        
        let rate = totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0
        
        // DEBUG: Логируем расчеты
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        print("📊 Month \(formatter.string(from: monthDate)): \(completedDays)/\(totalDays) = \(rate)")
        
        return rate
    }
}

// Data model находится в LineChartModels.swift
