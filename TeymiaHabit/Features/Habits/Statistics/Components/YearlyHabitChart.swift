import SwiftUI
import Charts

struct YearlyHabitChart: View {
    let habit: Habit

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
                canGoPrevious: currentYearIndex > 0,
                canGoNext: canNavigateToNextYear,
                averageLabel: chartAverageFormatted(chartData: chartData, habitType: habit.type),
                totalLabel: chartTotalFormatted(chartData: chartData, habitType: habit.type),
                selectedDateLabel: selectedDate.map { monthFormatter.string(from: $0) },
                selectedValueLabel: selectedDate.flatMap { date in
                    chartData.first { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
                }?.formattedValueWithoutSeconds,
                onPrevious: { withAnimation(.easeInOut(duration: 0.3)) { currentYearIndex -= 1 } },
                onNext: { withAnimation(.easeInOut(duration: 0.3)) { currentYearIndex += 1 } }
            )

            ChartContainer(currentIndex: $currentYearIndex, count: years.count) {
                chartView
            }
            .onChange(of: currentYearIndex) { _, _ in
                selectedDate = nil
                generateChartData()
            }
        }
        .sensoryFeedback(trigger: selectedDate) { old, new in
            shouldPlayChartHaptic(old: old, new: new, calendar: calendar) ? .selection : nil
        }
        .onAppear {
            setupYears()
            findCurrentYearIndex()
            generateChartData()
        }
        .onChange(of: habit.goal) { _, _ in generateChartData() }
        .onChange(of: habit.activeDays) { _, _ in generateChartData() }
    }

    // MARK: - Chart View

    private var chartView: some View {
        Chart(chartData) { dataPoint in
            BarMark(
                x: .value("Month", dataPoint.date, unit: .month),
                y: .value("Progress", dataPoint.value)
            )
            .foregroundStyle(dataPoint.value == 0 ? Color.secondary.gradient : habit.actualColor.gradient)
            .cornerRadius(8)
            .opacity(yearlyBarOpacity(for: dataPoint.date))
        }
        .chartXAxis {
            AxisMarks(values: chartData.map { $0.date }) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [2]))
                    .foregroundStyle(.appPrimary.opacity(0.2).gradient)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(firstLetterOfMonth(from: date))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.appPrimary.opacity(0.5).gradient)
                    }
                }
            }
        }
        .habitChartYAxis(values: habitChartYAxisValues(for: chartData, habitType: habit.type))
        .chartXSelection(value: $selectedDate)
        .onTapGesture {
            if selectedDate != nil {
                withAnimation(.easeOut(duration: 0.2)) { selectedDate = nil }
            }
        }
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

    private var monthFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "LLLL"; return f
    }

    private var canNavigateToNextYear: Bool {
        guard !years.isEmpty else { return false }
        let todayYear = calendar.dateComponents([.year], from: Date()).year!
        let displayYear = calendar.dateComponents([.year], from: currentYear).year!
        return displayYear < todayYear
    }

    // MARK: - Helpers

    private func yearlyBarOpacity(for date: Date) -> Double {
        guard let selected = selectedDate else { return 1.0 }
        return (calendar.component(.month, from: date) == calendar.component(.month, from: selected) &&
                calendar.component(.year, from: date) == calendar.component(.year, from: selected)) ? 1.0 : 0.3
    }

    private func firstLetterOfMonth(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM"
        return String(f.string(from: date).prefix(1)).uppercased()
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
}
