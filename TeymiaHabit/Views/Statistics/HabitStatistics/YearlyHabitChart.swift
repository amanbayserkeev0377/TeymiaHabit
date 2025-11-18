import SwiftUI
import Charts

struct YearlyHabitChart: View {
    let habit: Habit
    let updateCounter: Int
    
    @State private var years: [Date] = []
    @State private var currentYearIndex: Int = 0
    @State private var chartData: [ChartDataPoint] = []
    @State private var selectedDate: Date?
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            headerView
            chartView
            
        }
        .onAppear {
            setupYears()
            findCurrentYearIndex()
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
            if let old = oldValue, let new = newValue, !calendar.isDate(old, equalTo: new, toGranularity: .month) {
                HapticManager.shared.playSelection()
            }
            else if oldValue == nil && newValue != nil {
                HapticManager.shared.playSelection()
            }
        }
    }
    
    // MARK: - Header View
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: showPreviousYear) {
                    Image("chevron.left")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(canNavigateToPreviousYear ? .primary : Color.gray.opacity(0.5))
                        .contentShape(Rectangle())
                        .frame(width: 44, height: 44)
                }
                .disabled(!canNavigateToPreviousYear)
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
                
                Text(yearRangeString)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: showNextYear) {
                    Image("chevron.right")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(canNavigateToNextYear ? .primary : Color.gray.opacity(0.5))
                        .contentShape(Rectangle())
                        .frame(width: 44, height: 44)
                }
                .disabled(!canNavigateToNextYear)
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal, 8)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("average".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    Text(averageValueFormatted)
                        .font(.title2)
                        .fontWeight(.medium)
                        .withHabitGradient(habit)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let selectedDate = selectedDate,
                   let selectedDataPoint = chartData.first(where: {
                       calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month)
                   }) {
                    VStack(alignment: .center, spacing: 2) {
                        Text(monthYearFormatter.string(from: selectedDate).capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Text(selectedDataPoint.formattedValueWithoutSeconds)
                            .font(.title2)
                            .fontWeight(.medium)
                            .withHabitGradient(habit)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("total".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    Text(yearlyTotalFormatted)
                        .font(.title2)
                        .fontWeight(.medium)
                        .withHabitGradient(habit)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 0)
        }
    }
    
    @ViewBuilder
    private var chartView: some View {
            Chart(chartData) { dataPoint in
                BarMark(
                    x: .value("Month", dataPoint.date, unit: .month),
                    y: .value("Progress", dataPoint.value)
                )
                .foregroundStyle(barColor(for: dataPoint))
                .cornerRadius(30)
                .opacity(selectedDate == nil ? 1.0 : 
                        (calendar.component(.month, from: dataPoint.date) == calendar.component(.month, from: selectedDate!) &&
                         calendar.component(.year, from: dataPoint.date) == calendar.component(.year, from: selectedDate!) ? 1.0 : 0.4))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: xAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(firstLetterOfMonth(from: date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: yAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            if habit.type == .time {
                                Text(formatTimeWithoutSeconds(intValue))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(intValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
            .gesture(dragGesture)
            .onTapGesture {
                if selectedDate != nil {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedDate = nil
                    }
                }
            }
            .id("year-\(currentYearIndex)-\(updateCounter)")
    }
    
    // MARK: - Computed Properties
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                let horizontalDistance = value.translation.width
                let verticalDistance = abs(value.translation.height)
                
                if abs(horizontalDistance) > verticalDistance * 2 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if horizontalDistance > 0 && canNavigateToPreviousYear {
                            showPreviousYear()
                        } else if horizontalDistance < 0 && canNavigateToNextYear {
                            showNextYear()
                        }
                    }
                }
            }
    }
        
    private var currentYear: Date {
        guard !years.isEmpty && currentYearIndex >= 0 && currentYearIndex < years.count else {
            return Date()
        }
        return years[currentYearIndex]
    }
    
    private var yearRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: currentYear)
    }
    
    private var averageValueFormatted: String {
        guard !chartData.isEmpty else { return "0" }
        
        let activeMonthsData = chartData.filter { $0.value > 0 }
        guard !activeMonthsData.isEmpty else { return "0" }
        
        let total = activeMonthsData.reduce(0) { $0 + $1.value }
        let average = total / activeMonthsData.count
        
        switch habit.type {
        case .count:
            return "\(average)"
        case .time:
            return formatTimeWithoutSeconds(average)
        }
    }
    
    private var yearlyTotalFormatted: String {
        guard !chartData.isEmpty else { return "0" }
        
        let total = chartData.reduce(0) { $0 + $1.value }
        
        switch habit.type {
        case .count:
            return "\(total)"
        case .time:
            return formatTimeWithoutSeconds(total)
        }
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        return formatter
    }
    
    private var shortMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    private func firstLetterOfMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let monthName = formatter.string(from: date)
        return String(monthName.prefix(1)).uppercased()
    }
    
    private func formatTimeWithoutSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%0:%02d", minutes)
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
    
    private var xAxisValues: [Date] {
        return chartData.map { $0.date }
    }
    
    private var canNavigateToPreviousYear: Bool {
        return currentYearIndex > 0
    }
    
    private var canNavigateToNextYear: Bool {
        guard !years.isEmpty else { return false }
        
        let today = Date()
        let currentYearComponents = calendar.dateComponents([.year], from: today)
        let displayedYearComponents = calendar.dateComponents([.year], from: currentYear)
        
        return displayedYearComponents.year! < currentYearComponents.year!
    }
    
    // MARK: - Navigation Methods
    
    private func showPreviousYear() {
        guard canNavigateToPreviousYear else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentYearIndex -= 1
            selectedDate = nil
            generateChartData()
        }
    }
    
    private func showNextYear() {
        guard canNavigateToNextYear else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentYearIndex += 1
            selectedDate = nil
            generateChartData()
        }
    }
    
    // MARK: - Bar Color
    
    private func barColor(for dataPoint: ChartDataPoint) -> AnyShapeStyle {
        let value = dataPoint.value
        
        if value == 0 {
            return AppColorManager.getNoProgressBarStyle()
        }
        
        return AnyShapeStyle(habit.iconColor.color.gradient.opacity(0.9))
    }
    
    // MARK: - Helper Methods
    
    private func setupYears() {
        
        let today = Date()
        let currentYearComponents = calendar.dateComponents([.year], from: today)
        let currentYear = calendar.date(from: currentYearComponents) ?? today
        
        let effectiveStartDate = HistoryLimits.limitStartDate(habit.startDate)
        let habitStartComponents = calendar.dateComponents([.year], from: effectiveStartDate)
        let habitStartYear = calendar.date(from: habitStartComponents) ?? effectiveStartDate
        
        var yearsList: [Date] = []
        var currentYearDate = habitStartYear
        
        while currentYearDate <= currentYear {
            yearsList.append(currentYearDate)
            currentYearDate = calendar.date(byAdding: .year, value: 1, to: currentYearDate) ?? currentYearDate
        }
        
        years = yearsList
    }
    
    private func findCurrentYearIndex() {
        let today = Date()
        let currentYearComponents = calendar.dateComponents([.year], from: today)
        let currentYear = calendar.date(from: currentYearComponents) ?? today
        
        if let index = years.firstIndex(where: { calendar.isDate($0, equalTo: currentYear, toGranularity: .year) }) {
            currentYearIndex = index
        } else {
            currentYearIndex = max(0, years.count - 1)
        }
    }
    
    private func generateChartData() {
        guard !years.isEmpty && currentYearIndex >= 0 && currentYearIndex < years.count else {
            chartData = []
            return
        }
        
        let year = currentYear
        var data: [ChartDataPoint] = []
        
        for month in 1...12 {
            guard let monthDate = calendar.date(byAdding: .month, value: month - 1, to: year) else { continue }
            
            let monthProgress = calculateMonthlyProgress(for: monthDate)
            
            let dataPoint = ChartDataPoint(
                date: monthDate,
                value: monthProgress,
                goal: habit.goal,
                habit: habit
            )
            
            data.append(dataPoint)
        }
        
        chartData = data
    }
    
    private func calculateMonthlyProgress(for monthDate: Date) -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: monthDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
            return 0
        }
        
        var totalProgress = 0
        
        for day in 1...range.count {
            guard let currentDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) else { continue }
            
            if habit.isActiveOnDate(currentDate) && currentDate >= habit.startDate && currentDate <= Date() {
                totalProgress += habit.progressForDate(currentDate)
            }
        }
        
        return totalProgress
    }
}
