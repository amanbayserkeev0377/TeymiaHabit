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
                x: .value("Day", dataPoint.dayName), // CATEGORICAL данные
                y: .value("Progress", dataPoint.completionRate)
            )
            .foregroundStyle(habit.iconColor.color)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Day", dataPoint.dayName), // CATEGORICAL данные
                y: .value("Progress", dataPoint.completionRate)
            )
            .foregroundStyle(habit.iconColor.color.opacity(0.2))
        }
        .frame(height: 140)
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
        .chartYScale(domain: 0...1.0)
        .onAppear {
            generateChartData()
        }
    }
    
    // MARK: - Data Generation
    
    private func generateChartData() {
        let today = Date()
        var data: [WeeklyChartDataPoint] = []
        
        // Генерируем последние 7 дней
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
        return min(1.0, rate)
    }
}

// Data model находится в LineChartModels.swift
