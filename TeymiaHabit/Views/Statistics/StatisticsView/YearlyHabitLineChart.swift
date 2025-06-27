import SwiftUI
import Charts

/// Максимально упрощенный и быстрый годовой график
struct YearlyHabitLineChart: View {
    let habit: Habit
    
    @State private var chartData: [ChartDataPoint] = []
    @State private var isDataLoaded = false
    
    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header - всегда отображается мгновенно
            habitHeader
            
            // Chart section
            if isDataLoaded {
                yearlyChart
                    .padding(.horizontal, 8)
            } else {
                yearlyChartSkeleton
                    .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 12)
        .onAppear {
            loadDataAsync()
        }
        .onChange(of: habit.completions?.count) { _, _ in
            loadDataAsync()
        }
        .onChange(of: habit.goal) { _, _ in
            loadDataAsync()
        }
    }
    
    // MARK: - Header Component
    
    private var habitHeader: some View {
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
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 16)
                        .shimmer()
                }
                
                Text("last_12_months".localized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Chart Views
    
    private var yearlyChart: some View {
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
    }
    
    private var yearlyChartSkeleton: some View {
        VStack(spacing: 8) {
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
                .shimmer()
            
            HStack {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 20, height: 8)
                        .shimmer(delay: Double(index) * 0.1)
                    
                    if index < 5 { Spacer() }
                }
            }
        }
    }
    
    // MARK: - 🔥 ПРОСТАЯ И БЫСТРАЯ загрузка данных
    
    private func loadDataAsync() {
        Task { @MainActor in
            // Небольшая задержка для плавности
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            // Генерируем данные напрямую на главном потоке (проще и быстрее)
            let data = generateSimpleChartData()
            
            withAnimation(.easeOut(duration: 0.3)) {
                chartData = data
                isDataLoaded = true
            }
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
    
    // MARK: - Helper Properties
    
    private var currentPeriodProgress: String {
        guard !chartData.isEmpty else { return "0%" }
        
        let averageCompletion = chartData.reduce(0) { $0 + $1.completionPercentage } / Double(chartData.count)
        return "\(Int(averageCompletion * 100))%"
    }
}

// MARK: - Shimmer Effect Extension

extension View {
    func shimmer(delay: Double = 0) -> some View {
        self.modifier(ShimmerModifier(delay: delay))
    }
}

struct ShimmerModifier: ViewModifier {
    let delay: Double
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: isAnimating
            )
            .onAppear {
                if delay == 0 {
                    isAnimating = true
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        isAnimating = true
                    }
                }
            }
    }
}
