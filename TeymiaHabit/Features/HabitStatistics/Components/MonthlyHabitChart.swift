import SwiftUI
import Charts

struct MonthlyHabitChart: View {
    let habit: Habit
    let updateCounter: Int

    @State private var months: [Date] = []
    @State private var currentMonthIndex: Int = 0
    @State private var chartData: [ChartDataPoint] = []
    @State private var selectedDate: Date?

    private var calendar: Calendar { Calendar.userPreferred }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ChartPeriodHeader(
                title: DateFormatter.capitalizedNominativeMonthYear(from: currentMonth),
                canGoPrevious: canNavigateToPreviousMonth,
                canGoNext: canNavigateToNextMonth,
                averageLabel: averageFormatted,
                totalLabel: totalFormatted,
                selectedDateLabel: selectedDate.map { shortDateFormatter.string(from: $0) },
                selectedValueLabel: selectedDate.flatMap { date in
                    chartData.first { calendar.isDate($0.date, inSameDayAs: date) }
                }?.formattedValueWithoutSeconds,
                onPrevious: showPreviousMonth,
                onNext: showNextMonth
            )

            chartContainer
        }
        .onAppear {
            setupMonths()
            findCurrentMonthIndex()
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
        TabView(selection: $currentMonthIndex) {
            ForEach(months.indices, id: \.self) { index in
                chartView
                    .tag(index)
                    .padding(.horizontal, 16)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 180)
        .onChange(of: currentMonthIndex) { _, _ in
            selectedDate = nil
            generateChartData()
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    private var chartView: some View {
        Chart(chartData) { dataPoint in
            BarMark(
                x: .value("Day", dataPoint.date),
                y: .value("Progress", dataPoint.value)
            )
            .foregroundStyle(barColor(for: dataPoint))
            .cornerRadius(10)
            .opacity(barOpacity(for: dataPoint.date))
        }
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [2]))
                    .foregroundStyle(.white.opacity(0.2).gradient)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .fontDesign(.rounded)
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

    private var currentMonth: Date {
        guard !months.isEmpty, currentMonthIndex >= 0, currentMonthIndex < months.count else { return Date() }
        return months[currentMonthIndex]
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

    private var xAxisValues: [Date] {
        stride(from: 0, to: chartData.count, by: 5).compactMap {
            chartData.indices.contains($0) ? chartData[$0].date : nil
        }
    }

    private var shortDateFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f
    }

    private var canNavigateToPreviousMonth: Bool { currentMonthIndex > 0 }

    private var canNavigateToNextMonth: Bool {
        guard !months.isEmpty else { return false }
        let today = Date()
        let todayComps = calendar.dateComponents([.year, .month], from: today)
        let currentComps = calendar.dateComponents([.year, .month], from: currentMonth)
        return !(currentComps.year! > todayComps.year! ||
            (currentComps.year! == todayComps.year! && currentComps.month! >= todayComps.month!))
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

    private func setupMonths() {
        let today = Date()
        let todayComps = calendar.dateComponents([.year, .month], from: today)
        let currentMonth = calendar.date(from: todayComps) ?? today

        let effectiveStart = HistoryLimits.limitStartDate(habit.startDate)
        let startComps = calendar.dateComponents([.year, .month], from: effectiveStart)
        let startMonth = calendar.date(from: startComps) ?? effectiveStart

        var list: [Date] = []
        var current = startMonth
        while current <= currentMonth {
            list.append(current)
            current = calendar.date(byAdding: .month, value: 1, to: current) ?? current
        }
        months = list
    }

    private func findCurrentMonthIndex() {
        let todayComps = calendar.dateComponents([.year, .month], from: Date())
        let todayMonth = calendar.date(from: todayComps) ?? Date()
        if let idx = months.firstIndex(where: { calendar.isDate($0, equalTo: todayMonth, toGranularity: .month) }) {
            currentMonthIndex = idx
        } else {
            currentMonthIndex = max(0, months.count - 1)
        }
    }

    private func generateChartData() {
        guard !months.isEmpty, currentMonthIndex >= 0, currentMonthIndex < months.count,
              let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { chartData = []; return }

        chartData = (1...range.count).compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) else { return nil }
            let progress = (habit.isActiveOnDate(date) && date >= habit.startDate && date <= Date())
                ? habit.progressForDate(date) : 0
            return ChartDataPoint(date: date, value: progress, goal: habit.goal, habit: habit)
        }
    }

    // MARK: - Navigation

    private func showPreviousMonth() {
        guard canNavigateToPreviousMonth else { return }
        withAnimation(.easeInOut(duration: 0.3)) { currentMonthIndex -= 1 }
    }

    private func showNextMonth() {
        guard canNavigateToNextMonth else { return }
        withAnimation(.easeInOut(duration: 0.3)) { currentMonthIndex += 1 }
    }
}
