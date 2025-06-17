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
                x: .value("Month", dataPoint.date, unit: .month),
                y: .value("Progress", dataPoint.completionRate)
            )
            .foregroundStyle(habit.iconColor.color)
            .lineStyle(StrokeStyle(lineWidth: 1.5)) // ✅ Тоньше линия
            .interpolationMethod(.monotone) // ✅ КЛЮЧ: monotone = мягко БЕЗ выпирания!
            
            AreaMark(
                x: .value("Month", dataPoint.date, unit: .month),
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
            .interpolationMethod(.monotone) // ✅ И для области тоже monotone
        }
        .frame(height: 140)
        .chartYScale(domain: 0...1.0) // ✅ Строгие границы
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
    }
    
    private func generateChartData() {
        let today = Date()
        var data: [YearlyChartDataPoint] = []
        
        for monthOffset in 0..<12 {
            guard let date = calendar.date(byAdding: .month, value: -monthOffset, to: today) else { 
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
        
        chartData = data.reversed()
    }
    
    private func formatMonthName(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let monthName = formatter.string(from: date)
        
        let currentYear = calendar.component(.year, from: Date())
        let monthYear = calendar.component(.year, from: date)
        
        if monthYear != currentYear {
            return "\(String(monthName.prefix(1)))\(String(monthYear).suffix(2))"
        } else {
            return String(monthName.prefix(1)).uppercased()
        }
    }
    
    private func calculateMonthlyCompletionRate(for monthDate: Date) -> Double {
        guard let range = calendar.range(of: .day, in: .month, for: monthDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
            return 0
        }
        
        var totalDays = 0
        var completedDays = 0
        
        for day in 1...range.count {
            guard let currentDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) else { continue }
            
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
        return min(1.0, max(0.0, rate)) // ✅ Гарантируем 0-100%
    }
}
