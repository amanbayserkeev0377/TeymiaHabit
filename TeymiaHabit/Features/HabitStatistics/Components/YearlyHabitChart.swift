import SwiftUI
import Charts

struct YearlyHabitChart: View {
    let habit: Habit
    let updateCounter: Int

    @State private var years: [Date] = []
    @State private var currentYearIndex: Int = 0
    @State private var chartData: [ChartDataPoint] = []
    @State private var selectedDate: Date?

    private var calendar: Calendar { Calendar.userPreferred }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ChartPeriodHeader(
                title: yearString,
                canGoPrevious: canNavigateToPreviousYear,
                canGoNext: canNavigateToNextYear,
                averageLabel: averageFormatted,
                totalLabel: totalFormatted,
                selectedDateLabel: selectedDate.map { monthFormatter.string(from: $0) },
                selectedValueLabel: selectedDate.flatMap { date in
                    chartData.first { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
                }?.formattedValueWithoutSeconds,
                onPrevious: showPreviousYear,
                onNext: showNextYear
            )

            chartContainer
        }
        .onAppear {
            setupYears()
            findCurrentYearIndex()
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
        TabView(selection: $currentYearIndex) {
            ForEach(years.indices, id: \.self) { index in
                chartView
                    .tag(index)
                    .padding(.horizontal, 16)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 180)
        .onChange(of: currentYearIndex) { _, _ in
            selectedDate = nil
            generateChartData()
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    private var chartView: some View {
        Chart(chartData) { dataPoint in
            BarMark(
                x: .value("Month", dataPoint.date, unit: .month),
                y: .value("Progress", dataPoint.value)
            )
            .foregroundStyle(barColor(for: dataPoint))
            .cornerRadius(8)
            .opacity(barOpacity(for: dataPoint.date))
        }
        .chartXAxis {
            AxisMarks(values: chartData.map { $0.date }) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [2]))
                    .foregroundStyle(.white.opacity(0.2).gradient)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(firstLetterOfMonth(from: date))
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

    private var currentYear: Date {
        guard !years.isEmpty, currentYearIndex >= 0, currentYearIndex < years.count else { return Date() }
        return years[currentYearIndex]
    }

    private var yearString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy"
        return f.string(from: currentYear)
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

    private var monthFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "LLLL"; return f
    }

    private var canNavigateToPreviousYear: Bool { currentYearIndex > 0 }

    private var canNavigateToNextYear: Bool {
        guard !years.isEmpty else { return false }
        let todayYear = calendar.dateComponents([.year], from: Date()).year!
        let displayYear = calendar.dateComponents([.year], from: currentYear).year!
        return displayYear < todayYear
    }

    // MARK: - Helpers

    private func barOpacity(for date: Date) -> Double {
        guard let selected = selectedDate else { return 1.0 }
        return (calendar.component(.month, from: date) == calendar.component(.month, from: selected) &&
                calendar.component(.year,  from: date) == calendar.component(.year,  from: selected)) ? 1.0 : 0.3
    }

    private func clearSelection() {
        if selectedDate != nil {
            withAnimation(.easeOut(duration: 0.2)) { selectedDate = nil }
        }
    }

    private func playHapticOnChange(oldValue: Date?, newValue: Date?) {
        if let old = oldValue, let new = newValue, !calendar.isDate(old, equalTo: new, toGranularity: .month) {
            HapticManager.shared.playSelection()
        } else if oldValue == nil && newValue != nil {
            HapticManager.shared.playSelection()
        }
    }

    private func firstLetterOfMonth(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM"
        return String(f.string(from: date).prefix(1)).uppercased()
    }

    private func barColor(for dataPoint: ChartDataPoint) -> AnyShapeStyle {
        dataPoint.value == 0
            ? AppColorManager.getNoProgressBarStyle()
            : AnyShapeStyle(habit.iconColor.color.gradient.opacity(0.9))
    }

    // MARK: - Setup

    private func setupYears() {
        let today = Date()
        let todayComps = calendar.dateComponents([.year], from: today)
        let currentYear = calendar.date(from: todayComps) ?? today

        let effectiveStart = HistoryLimits.limitStartDate(habit.startDate)
        let startComps = calendar.dateComponents([.year], from: effectiveStart)
        let startYear = calendar.date(from: startComps) ?? effectiveStart

        var list: [Date] = []
        var current = startYear
        while current <= currentYear {
            list.append(current)
            current = calendar.date(byAdding: .year, value: 1, to: current) ?? current
        }
        years = list
    }

    private func findCurrentYearIndex() {
        let todayComps = calendar.dateComponents([.year], from: Date())
        let todayYear = calendar.date(from: todayComps) ?? Date()
        if let idx = years.firstIndex(where: { calendar.isDate($0, equalTo: todayYear, toGranularity: .year) }) {
            currentYearIndex = idx
        } else {
            currentYearIndex = max(0, years.count - 1)
        }
    }

    private func generateChartData() {
        guard !years.isEmpty, currentYearIndex >= 0, currentYearIndex < years.count else {
            chartData = []; return
        }
        chartData = (1...12).compactMap { month in
            guard let date = calendar.date(byAdding: .month, value: month - 1, to: currentYear) else { return nil }
            return ChartDataPoint(
                date: date,
                value: calculateMonthlyProgress(for: date),
                goal: habit.goal,
                habit: habit
            )
        }
    }

    private func calculateMonthlyProgress(for monthDate: Date) -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: monthDate),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))
        else { return 0 }

        return (1...range.count).reduce(0) { total, day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay),
                  habit.isActiveOnDate(date), date >= habit.startDate, date <= Date()
            else { return total }
            return total + habit.progressForDate(date)
        }
    }

    // MARK: - Navigation

    private func showPreviousYear() {
        guard canNavigateToPreviousYear else { return }
        withAnimation(.easeInOut(duration: 0.3)) { currentYearIndex -= 1 }
    }

    private func showNextYear() {
        guard canNavigateToNextYear else { return }
        withAnimation(.easeInOut(duration: 0.3)) { currentYearIndex += 1 }
    }
}
