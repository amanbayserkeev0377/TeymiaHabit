import SwiftUI
import Charts

struct WeeklyHabitChart: View {
    let habit: Habit
    let updateCounter: Int

    @State private var weeks: [Date] = []
    @State private var currentWeekIndex: Int = 0
    @State private var chartData: [ChartDataPoint] = []
    @State private var selectedDate: Date?

    private var calendar: Calendar { Calendar.userPreferred }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ChartPeriodHeader(
                title: weekRangeString,
                canGoPrevious: canNavigateToPreviousWeek,
                canGoNext: canNavigateToNextWeek,
                averageLabel: averageFormatted,
                totalLabel: totalFormatted,
                selectedDateLabel: selectedDate.map { shortDateFormatter.string(from: $0) },
                selectedValueLabel: selectedDate.flatMap { date in
                    chartData.first { calendar.isDate($0.date, inSameDayAs: date) }
                }?.formattedValueWithoutSeconds,
                onPrevious: showPreviousWeek,
                onNext: showNextWeek
            )

            chartContainer
        }
        .onAppear {
            setupWeeks()
            findCurrentWeekIndex()
            generateChartData()
        }
        .onChange(of: habit.goal) { _, _ in generateChartData() }
        .onChange(of: habit.activeDays) { _, _ in generateChartData() }
        .onChange(of: updateCounter) { _, _ in generateChartData() }
        .onChange(of: selectedDate, playHapticOnChange)
    }

    // MARK: - Chart Container

    @ViewBuilder
    private var chartContainer: some View {
        TabView(selection: $currentWeekIndex) {
            ForEach(weeks.indices, id: \.self) { index in
                chartView
                    .tag(index)
                    .padding(.horizontal, 16)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 180)
        .onChange(of: currentWeekIndex) { _, _ in
            selectedDate = nil
            generateChartData()
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    private var chartView: some View {
        Chart(chartData) { dataPoint in
            BarMark(
                x: .value("Day", dataPoint.date, unit: .day),
                y: .value("Progress", dataPoint.value)
            )
            .foregroundStyle(barColor(for: dataPoint))
            .cornerRadius(10)
            .opacity(barOpacity(for: dataPoint.date))
        }
        .chartXAxis {
            AxisMarks(values: chartData.map { $0.date }) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [2]))
                    .foregroundStyle(.white.opacity(0.2).gradient)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        let index = calendar.component(.weekday, from: date) - 1
                        Text(calendar.shortWeekdaySymbols[index])
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.2).gradient)
                    }
                }
            }
        }
        .habitChartYAxis(values: yAxisValues)
        .chartXSelection(value: $selectedDate)
        .onTapGesture { clearSelection() }
        .frame(height: 180)
    }

    // MARK: - Computed Properties

    private var currentWeekStart: Date {
        guard !weeks.isEmpty, currentWeekIndex >= 0, currentWeekIndex < weeks.count else { return Date() }
        return weeks[currentWeekIndex]
    }

    private var currentWeekEnd: Date {
        calendar.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
    }

    private var weekRangeString: String {
        let formatter = DateFormatter()
        if calendar.isDate(currentWeekStart, equalTo: currentWeekEnd, toGranularity: .month) {
            let start = calendar.component(.day, from: currentWeekStart)
            let end = calendar.component(.day, from: currentWeekEnd)
            formatter.dateFormat = "MMM yyyy"
            return "\(start)–\(end) \(formatter.string(from: currentWeekStart))"
        } else {
            formatter.dateFormat = "d MMM"
            let startStr = formatter.string(from: currentWeekStart)
            let endStr = formatter.string(from: currentWeekEnd)
            formatter.dateFormat = "yyyy"
            return "\(startStr)–\(endStr) \(formatter.string(from: currentWeekEnd))"
        }
    }

    private var averageFormatted: String {
        let active = chartData.filter { $0.value > 0 }
        guard !active.isEmpty else { return "0" }
        let avg = active.reduce(0) { $0 + $1.value } / active.count
        return habit.type == .time ? avg.formattedAsChartDuration() : "\(avg)"
    }

    private var totalFormatted: String {
        let total = chartData.reduce(0) { $0 + $1.value }
        return habit.type == .time ? total.formattedAsChartDuration() : "\(total)"
    }

    private var yAxisValues: [Int] {
        habitChartYAxisValues(for: chartData, habitType: habit.type)
    }

    private var shortDateFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f
    }

    private var canNavigateToPreviousWeek: Bool { currentWeekIndex > 0 }

    private var canNavigateToNextWeek: Bool {
        guard !weeks.isEmpty else { return false }
        let todayStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return currentWeekIndex < weeks.count - 1 && currentWeekStart < todayStart
    }

    // MARK: - Helpers

    private func barOpacity(for date: Date) -> Double {
        guard let selected = selectedDate else { return 1.0 }
        return calendar.isDate(date, inSameDayAs: selected) ? 1.0 : 0.3
    }

    private func clearSelection() {
        if selectedDate != nil {
            withAnimation(.easeOut(duration: 0.2)) { selectedDate = nil }
        }
    }

    private func playHapticOnChange(oldValue: Date?, newValue: Date?) {
        if let old = oldValue, let new = newValue, !calendar.isDate(old, inSameDayAs: new) {
            HapticManager.shared.playSelection()
        } else if oldValue == nil && newValue != nil {
            HapticManager.shared.playSelection()
        }
    }

    private func barColor(for dataPoint: ChartDataPoint) -> AnyShapeStyle {
        if !habit.isActiveOnDate(dataPoint.date) || dataPoint.date > Date() {
            return AppColorManager.getInactiveBarStyle()
        }
        if dataPoint.value == 0 { return AppColorManager.getNoProgressBarStyle() }
        return AppColorManager.getChartBarStyle(
            isCompleted: dataPoint.isCompleted,
            isExceeded: dataPoint.isOverAchieved,
            habit: habit
        )
    }

    // MARK: - Setup

    private func setupWeeks() {
        let today = Date()
        let todayStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let effectiveStart = HistoryLimits.limitStartDate(habit.startDate)
        let habitStart = calendar.dateInterval(of: .weekOfYear, for: effectiveStart)?.start ?? effectiveStart

        var list: [Date] = []
        var current = habitStart
        while current <= todayStart {
            list.append(current)
            current = calendar.date(byAdding: .weekOfYear, value: 1, to: current) ?? current
        }
        weeks = list
    }

    private func findCurrentWeekIndex() {
        let todayStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        if let idx = weeks.firstIndex(where: { calendar.isDate($0, equalTo: todayStart, toGranularity: .day) }) {
            currentWeekIndex = idx
        } else {
            currentWeekIndex = max(0, weeks.count - 1)
        }
    }

    private func generateChartData() {
        guard !weeks.isEmpty, currentWeekIndex >= 0, currentWeekIndex < weeks.count else {
            chartData = []; return
        }
        chartData = (0...6).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: currentWeekStart) else { return nil }
            let progress = (habit.isActiveOnDate(date) && date >= habit.startDate && date <= Date())
                ? habit.progressForDate(date) : 0
            return ChartDataPoint(date: date, value: progress, goal: habit.goal, habit: habit)
        }
    }

    // MARK: - Navigation

    private func showPreviousWeek() {
        guard canNavigateToPreviousWeek else { return }
        withAnimation(.easeInOut(duration: 0.3)) { currentWeekIndex -= 1 }
    }

    private func showNextWeek() {
        guard canNavigateToNextWeek else { return }
        withAnimation(.easeInOut(duration: 0.3)) { currentWeekIndex += 1 }
    }
}
