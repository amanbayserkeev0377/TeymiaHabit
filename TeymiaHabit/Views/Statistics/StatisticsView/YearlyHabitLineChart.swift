import SwiftUI
import Charts

struct LazyYearlyHabitCard: View {
    let habit: Habit
    let onTap: () -> Void
    
    @State private var isDataLoaded = false
    @State private var chartData: [YearlyChartDataPoint] = []
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header (всегда показываем мгновенно)
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
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        if isDataLoaded {
                            Text(currentPeriodProgress)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(habit.iconColor.color)
                        } else {
                            // Skeleton для статистики
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 16)
                        }
                        
                        Text("last_12_months".localized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                
                // Chart - ленивая загрузка
                if isDataLoaded {
                    yearlyChart
                } else {
                    yearlyChartSkeleton
                }
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if !isDataLoaded {
                Task {
                    // Небольшая задержка чтобы UI отрисовался
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    await loadDataAsync()
                }
            }
        }
    }
    
    // MARK: - Async Data Loading
    
    @MainActor
    private func loadDataAsync() async {
        await Task {
            generateOptimizedChartData()
        }.value
        
        withAnimation(.easeOut(duration: 0.3)) {
            isDataLoaded = true
        }
    }
    
    // MARK: - Chart Views
    
    private var yearlyChart: some View {
        Chart(chartData) { dataPoint in
            LineMark(
                x: .value("Month", dataPoint.date, unit: .month),
                y: .value("Progress", dataPoint.completionRate)
            )
            .foregroundStyle(habit.iconColor.color)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.monotone)
            
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
        .padding(.horizontal, 8)
    }
    
    private var yearlyChartSkeleton: some View {
        VStack(spacing: 8) {
            // Chart area skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 140)
                .overlay(
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(habit.iconColor.color)
                        
                        Text("Loading chart...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                )
            
            // Axis labels skeleton
            HStack {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 12, height: 8)
                    
                    if _ < 5 { Spacer() }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 8)
        .redacted(reason: .placeholder)
    }
    
    // MARK: - Data Generation (оптимизированная)
    
    private func generateOptimizedChartData() {
        let today = Date()
        let yearlyProgressCache = buildYearlyProgressCache()
        
        var data: [YearlyChartDataPoint] = []
        
        for monthOffset in 0..<12 {
            guard let date = calendar.date(byAdding: .month, value: -monthOffset, to: today) else {
                continue
            }
            
            let monthName = formatMonthName(date: date)
            let completionRate = calculateMonthlyCompletionRateFromCache(for: date, cache: yearlyProgressCache)
            
            data.append(YearlyChartDataPoint(
                monthName: monthName,
                date: date,
                completionRate: completionRate
            ))
        }
        
        chartData = data.reversed()
    }
    
    // MARK: - Helper Methods (сохраняем оптимизированные версии)
    
    private func buildYearlyProgressCache() -> [String: Int] {
        var cache: [String: Int] = [:]
        
        let today = Date()
        guard let startDate = calendar.date(byAdding: .month, value: -11, to: today),
              let completions = habit.completions else { return cache }
        
        for completion in completions {
            if completion.date >= startDate && completion.date <= today {
                let dateKey = formatDateKey(completion.date)
                cache[dateKey] = (cache[dateKey] ?? 0) + completion.value
            }
        }
        
        return cache
    }
    
    private func calculateMonthlyCompletionRateFromCache(for monthDate: Date, cache: [String: Int]) -> Double {
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
                
                let dateKey = formatDateKey(currentDate)
                let progress = cache[dateKey] ?? 0
                
                if progress >= habit.goal {
                    completedDays += 1
                }
            }
        }
        
        let rate = totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0
        return min(1.0, max(0.0, rate))
    }
    
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
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
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    private var currentPeriodProgress: String {
        let today = Date()
        
        var totalActiveDays = 0
        var completedDays = 0
        
        for monthOffset in 0..<12 {
            guard let date = calendar.date(byAdding: .month, value: monthOffset - 11, to: today) else { continue }
            
            if habit.isActiveOnDate(date) && date <= Date() {
                totalActiveDays += 1
                if habit.progressForDate(date) >= habit.goal {
                    completedDays += 1
                }
            }
        }
        
        let percentage = totalActiveDays > 0 ? Int((Double(completedDays) / Double(totalActiveDays)) * 100) : 0
        return "\(percentage)%"
    }
}
