import SwiftUI
import Charts

struct WeeklyHabitChart: View {
    let habit: Habit
    let updateCounter: Int
    
    @State private var weeks: [Date] = []
    @State private var currentWeekIndex: Int = 0
    @State private var chartData: [ChartDataPoint] = []
    @State private var selectedDate: Date?
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            chartContainer
        }
        .onAppear {
            setupWeeks()
            findCurrentWeekIndex()
            generateChartData()
        }
        .onChange(of: habit.goal) { _, _ in
            generateChartData()
        }
        .onChange(of: habit.activeDays) { _, _ in
            generateChartData()
        }
        .onChange(of: updateCounter) { _, _ in
            generateChartData()
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            if let old = oldValue, let new = newValue, !calendar.isDate(old, inSameDayAs: new) {
                HapticManager.shared.playSelection()
            }
            else if oldValue == nil && newValue != nil {
                HapticManager.shared.playSelection()
            }
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: showPreviousWeek) {
                    Image("chevron.left")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(canNavigateToPreviousWeek ? .primary : Color.gray.opacity(0.5))
                        .contentShape(Rectangle())
                }
                .disabled(!canNavigateToPreviousWeek)
                .buttonStyle(.borderless)
                
                Spacer()
                
                Text(weekRangeString)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                
                Spacer()
                
                Button(action: showNextWeek) {
                    Image("chevron.right")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(canNavigateToNextWeek ? .primary : Color.gray.opacity(0.5))
                        .contentShape(Rectangle())
                }
                .disabled(!canNavigateToNextWeek)
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("average".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                    
                    Text(averageValueFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let selectedDate = selectedDate,
                   let selectedDataPoint = chartData.first(where: {
                       calendar.isDate($0.date, inSameDayAs: selectedDate)
                   }) {
                    VStack(alignment: .center, spacing: 2) {
                        Text(shortDateFormatter.string(from: selectedDate).capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                        
                        Text(selectedDataPoint.formattedValueWithoutSeconds)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("total".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                    
                    Text(weeklyTotalFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Chart Container with TabView
    
    @ViewBuilder
    private var chartContainer: some View {
        TabView(selection: $currentWeekIndex) {
            ForEach(weeks.indices, id: \.self) { index in
                chartView(for: index)
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
    private func chartView(for index: Int) -> some View {
        Chart(chartData) { dataPoint in
            BarMark(
                x: .value("Day", dataPoint.date, unit: .day),
                y: .value("Progress", dataPoint.value)
            )
            .foregroundStyle(barColor(for: dataPoint))
            .cornerRadius(10)
            .opacity(selectedDate == nil ? 1.0 :
                    (calendar.isDate(dataPoint.date, inSameDayAs: selectedDate!) ? 1.0 : 0.3))
        }
        .chartXAxis {
            AxisMarks(values: chartData.map { $0.date }) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [2]))
                    .foregroundStyle(Color.secondary.opacity(0.2))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        let weekdayIndex = calendar.component(.weekday, from: date) - 1
                        let shortName = calendar.shortWeekdaySymbols[weekdayIndex]
                        Text(shortName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: yAxisValues) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [3]))
                    .foregroundStyle(Color.secondary.opacity(0.2))
            }
        }
        .chartXSelection(value: $selectedDate)
        .onTapGesture {
            if selectedDate != nil {
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedDate = nil
                }
            }
        }
        .frame(height: 180)
    }
    
    // MARK: - Computed Properties
    
    private var currentWeekStart: Date {
        guard !weeks.isEmpty && currentWeekIndex >= 0 && currentWeekIndex < weeks.count else {
            return Date()
        }
        return weeks[currentWeekIndex]
    }
    
    private var currentWeekEnd: Date {
        calendar.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
    }
    
    private var weekRangeString: String {
        let formatter = DateFormatter()
        
        if calendar.isDate(currentWeekStart, equalTo: currentWeekEnd, toGranularity: .month) {
            let startDay = calendar.component(.day, from: currentWeekStart)
            let endDay = calendar.component(.day, from: currentWeekEnd)
            formatter.dateFormat = "MMM yyyy"
            let monthYear = formatter.string(from: currentWeekStart)
            return "\(startDay)–\(endDay) \(monthYear)"
        } else {
            formatter.dateFormat = "d MMM"
            let startString = formatter.string(from: currentWeekStart)
            let endString = formatter.string(from: currentWeekEnd)
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: currentWeekEnd)
            return "\(startString)–\(endString) \(year)"
        }
    }
    
    private var averageValueFormatted: String {
        guard !chartData.isEmpty else { return "0" }
        
        let activeDaysData = chartData.filter { $0.value > 0 }
        guard !activeDaysData.isEmpty else { return "0" }
        
        let total = activeDaysData.reduce(0) { $0 + $1.value }
        let average = total / activeDaysData.count
        
        switch habit.type {
        case .count:
            return "\(average)"
        case .time:
            return formatTimeWithoutSeconds(average)
        }
    }
    
    private var weeklyTotalFormatted: String {
        guard !chartData.isEmpty else { return "0" }
        
        let total = chartData.reduce(0) { $0 + $1.value }
        
        switch habit.type {
        case .count:
            return "\(total)"
        case .time:
            return formatTimeWithoutSeconds(total)
        }
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }
    
    private func formatTimeWithoutSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else if minutes > 0 {
            return String(format: "0:%02d", minutes)
        } else {
            return "0"
        }
    }
    
    private var yAxisValues: [Int] {
        guard !chartData.isEmpty else { return [0] }
        
        let maxValue = chartData.map { $0.value }.max() ?? 0
        guard maxValue > 0 else { return [0] }
        
        let displayMaxValue = habit.type == .time ? maxValue / 3600 : maxValue
        let step = max(1, displayMaxValue / 3)
        
        let values = [0, step, step * 2, step * 3].filter { $0 <= displayMaxValue + step/2 }
        
        return habit.type == .time ? values.map { $0 * 3600 } : values
    }
    
    private var canNavigateToPreviousWeek: Bool {
        return currentWeekIndex > 0
    }
    
    private var canNavigateToNextWeek: Bool {
        guard !weeks.isEmpty else { return false }
        
        let today = Date()
        let todayWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return currentWeekIndex < weeks.count - 1 && currentWeekStart < todayWeekStart
    }
    
    // MARK: - Navigation Methods
    
    private func showPreviousWeek() {
        guard canNavigateToPreviousWeek else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentWeekIndex -= 1
        }
    }
    
    private func showNextWeek() {
        guard canNavigateToNextWeek else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentWeekIndex += 1
        }
    }
    
    // MARK: - Bar Color
    
    private func barColor(for dataPoint: ChartDataPoint) -> AnyShapeStyle {
        let date = dataPoint.date
        let value = dataPoint.value
        
        if !habit.isActiveOnDate(date) || date > Date() {
            return AppColorManager.getInactiveBarStyle()
        }
        
        if value == 0 {
            return AppColorManager.getNoProgressBarStyle()
        }
        
        return AppColorManager.getChartBarStyle(
            isCompleted: dataPoint.isCompleted,
            isExceeded: dataPoint.isOverAchieved,
            habit: habit
        )
    }
    
    // MARK: - Helper Methods
    
    private func setupWeeks() {
        let today = Date()
        let todayWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        let effectiveStartDate = HistoryLimits.limitStartDate(habit.startDate)
        let habitStartWeekStart = calendar.dateInterval(of: .weekOfYear, for: effectiveStartDate)?.start ?? effectiveStartDate
        
        var weeksList: [Date] = []
        var currentWeek = habitStartWeekStart
        
        while currentWeek <= todayWeekStart {
            weeksList.append(currentWeek)
            currentWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
        }
        
        weeks = weeksList
    }
    
    private func findCurrentWeekIndex() {
        let today = Date()
        let todayWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        if let index = weeks.firstIndex(where: { calendar.isDate($0, equalTo: todayWeekStart, toGranularity: .day) }) {
            currentWeekIndex = index
        } else {
            currentWeekIndex = max(0, weeks.count - 1)
        }
    }
    
    private func generateChartData() {
        guard !weeks.isEmpty && currentWeekIndex >= 0 && currentWeekIndex < weeks.count else {
            chartData = []
            return
        }
        
        let weekStart = currentWeekStart
        var data: [ChartDataPoint] = []
        
        for dayOffset in 0...6 {
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            
            let progress = habit.isActiveOnDate(currentDate) && currentDate >= habit.startDate && currentDate <= Date()
                ? habit.progressForDate(currentDate)
                : 0
            
            let dataPoint = ChartDataPoint(
                date: currentDate,
                value: progress,
                goal: habit.goal,
                habit: habit
            )
            
            data.append(dataPoint)
        }
        
        chartData = data
    }
}
