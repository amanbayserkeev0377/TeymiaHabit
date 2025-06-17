import SwiftUI
import Charts

struct MonthlyHabitLineChart: View {
    let habit: Habit
    
    @State private var chartData: [MonthlyChartDataPoint] = []
    
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
        var data: [MonthlyChartDataPoint] = []
        
        // Генерируем последние 30 дней с равномерным sampling (7 точек)
        let sampleOffsets = [29, 24, 19, 14, 9, 4, 0] // Дни назад от сегодня
        
        for dayOffset in sampleOffsets {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let dayName = formatDayName(date: date)
            let completionRate = calculateCompletionRate(for: date)
            
            data.append(MonthlyChartDataPoint(
                dayName: dayName,
                date: date,
                completionRate: completionRate
            ))
        }
        
        chartData = data
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
}

// Data model находится в LineChartModels.swift
