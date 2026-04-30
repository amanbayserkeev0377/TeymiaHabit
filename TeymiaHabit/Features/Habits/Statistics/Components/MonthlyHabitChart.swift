import SwiftUI
import Charts

struct MonthlyHabitChart: View {
    let habit: Habit

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
                canGoPrevious: currentMonthIndex > 0,
                canGoNext: canNavigateToNextMonth,
                averageLabel: chartAverageFormatted(chartData: chartData, habitType: habit.type),
                totalLabel: chartTotalFormatted(chartData: chartData, habitType: habit.type),
                selectedDateLabel: selectedDate.map { shortDateFormatter.string(from: $0) },
                selectedValueLabel: selectedDate.flatMap { date in
                    chartData.first { calendar.isDate($0.date, inSameDayAs: date) }
                }?.formattedValueWithoutSeconds,
                onPrevious: { withAnimation(.easeInOut(duration: 0.3)) { currentMonthIndex -= 1 } },
                onNext: { withAnimation(.easeInOut(duration: 0.3)) { currentMonthIndex += 1 } }
            )

            ChartContainer(currentIndex: $currentMonthIndex, count: months.count) {
                chartView
            }
            .onChange(of: currentMonthIndex) { _, _ in
                selectedDate = nil
                generateChartData()
            }
        }
        .sensoryFeedback(trigger: selectedDate) { old, new in
            shouldPlayChartHaptic(old: old, new: new, calendar: calendar) ? .selection : nil
        }
        .onAppear {
            setupMonths()
            findCurrentMonthIndex()
            generateChartData()
        }
        .onChange(of: habit.goal) { _, _ in generateChartData() }
        .onChange(of: habit.activeDays) { _, _ in generateChartData() }
    }

    // MARK: - Chart View

    private var chartView: some View {
        Chart(chartData) { dataPoint in
            BarMark(
                x: .value("Day", dataPoint.date),
                y: .value("Progress", dataPoint.value)
            )
            .foregroundStyle(habitBarColor(for: dataPoint, habit: habit))
            .cornerRadius(8)
            .opacity(habitBarOpacity(for: dataPoint.date, selected: selectedDate, calendar: calendar))
        }
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [2]))
                    .foregroundStyle(.appPrimary.opacity(0.2).gradient)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .fontDesign(.rounded)
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

    private var currentMonth: Date {
        guard !months.isEmpty, currentMonthIndex >= 0, currentMonthIndex < months.count else { return Date() }
        return months[currentMonthIndex]
    }

    private var xAxisValues: [Date] {
        stride(from: 0, to: chartData.count, by: 5).compactMap {
            chartData.indices.contains($0) ? chartData[$0].date : nil
        }
    }

    private var shortDateFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f
    }

    private var canNavigateToNextMonth: Bool {
        guard !months.isEmpty else { return false }
        let today = Date()
        let todayComps = calendar.dateComponents([.year, .month], from: today)
        let currentComps = calendar.dateComponents([.year, .month], from: currentMonth)
        return !(currentComps.year! > todayComps.year! ||
            (currentComps.year! == todayComps.year! && currentComps.month! >= todayComps.month!))
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
}
