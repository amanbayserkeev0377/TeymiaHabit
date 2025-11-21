import SwiftUI
import Charts

struct MonthlyHabitChart: View {
    let habit: Habit
    let updateCounter: Int
    
    @State private var months: [Date] = []
    @State private var currentMonthIndex: Int = 0
    @State private var chartData: [ChartDataPoint] = []
    @State private var selectedDate: Date?
    @State private var animationProgress: CGFloat = 0 // Progress from 0 to 1
    
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
            setupMonths()
            findCurrentMonthIndex()
            generateChartData()
            triggerAnimation()
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
                Button(action: showPreviousMonth) {
                    Image("chevron.left")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(canNavigateToPreviousMonth ? .primary : Color.gray.opacity(0.5))
                        .contentShape(Rectangle())
                }
                .disabled(!canNavigateToPreviousMonth)
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
                
                Text(monthRangeString)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                
                Spacer()
                
                Button(action: showNextMonth) {
                    Image("chevron.right")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(canNavigateToNextMonth ? .primary : Color.gray.opacity(0.5))
                        .contentShape(Rectangle())
                }
                .disabled(!canNavigateToNextMonth)
                .buttonStyle(BorderlessButtonStyle())
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
                    
                    Text(monthlyTotalFormatted)
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
        TabView(selection: $currentMonthIndex) {
            ForEach(months.indices, id: \.self) { index in
                chartView(for: index)
                    .tag(index)
            }
            .padding(.horizontal, 16)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 180)
        .onChange(of: currentMonthIndex) { _, _ in
            selectedDate = nil
            generateChartData()
            triggerAnimation()
        }
    }
    
    // MARK: - Chart View
    
    @ViewBuilder
    private func chartView(for index: Int) -> some View {
        GeometryReader { geometry in
            Chart(chartData) { dataPoint in
                BarMark(
                    x: .value("Day", dataPoint.date),
                    y: .value("Progress", dataPoint.value)
                )
                .foregroundStyle(barColor(for: dataPoint))
                .cornerRadius(30)
                .opacity(selectedDate == nil ? 1.0 :
                        (calendar.isDate(dataPoint.date, inSameDayAs: selectedDate!) ? 1.0 : 0.3))
            }
            .chartXAxis {
                AxisMarks(values: xAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [3]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text("\(calendar.component(.day, from: date))")
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
            .mask(
                // Mask that reveals from bottom to top
                VStack(spacing: 0) {
                    // Empty space at top (hidden part)
                    Color.clear
                        .frame(height: geometry.size.height * (1 - animationProgress))
                    
                    // Visible part from bottom
                    Color.black
                        .frame(height: geometry.size.height * animationProgress)
                }
            )
        }
        .frame(height: 180)
    }
    
    // MARK: - Computed Properties
    
    private var currentMonth: Date {
        guard !months.isEmpty && currentMonthIndex >= 0 && currentMonthIndex < months.count else {
            return Date()
        }
        return months[currentMonthIndex]
    }
    
    private var monthRangeString: String {
        return DateFormatter.capitalizedNominativeMonthYear(from: currentMonth)
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
    
    private var monthlyTotalFormatted: String {
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
    
    private var xAxisValues: [Date] {
        return Array(stride(from: 0, to: chartData.count, by: 5)).compactMap {
            chartData.indices.contains($0) ? chartData[$0].date : nil
        }
    }
    
    private var canNavigateToPreviousMonth: Bool {
        return currentMonthIndex > 0
    }
    
    private var canNavigateToNextMonth: Bool {
        guard !months.isEmpty else { return false }
        
        let today = Date()
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        let displayedMonthComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        
        return !(displayedMonthComponents.year! > currentMonthComponents.year! ||
                 (displayedMonthComponents.year! == currentMonthComponents.year! &&
                  displayedMonthComponents.month! >= currentMonthComponents.month!))
    }
    
    // MARK: - Navigation Methods
    
    private func showPreviousMonth() {
        guard canNavigateToPreviousMonth else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonthIndex -= 1
        }
    }
    
    private func showNextMonth() {
        guard canNavigateToNextMonth else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonthIndex += 1
        }
    }
    
    // MARK: - Animation
    
    private func triggerAnimation() {
        // Reset animation
        animationProgress = 0
        
        // Animate from bottom to top
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.5)) {
                animationProgress = 1.0
            }
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
    
    private func setupMonths() {
        let today = Date()
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        let currentMonth = calendar.date(from: currentMonthComponents) ?? today
        
        let effectiveStartDate = HistoryLimits.limitStartDate(habit.startDate)
        let habitStartComponents = calendar.dateComponents([.year, .month], from: effectiveStartDate)
        let habitStartMonth = calendar.date(from: habitStartComponents) ?? effectiveStartDate
        
        var monthsList: [Date] = []
        var currentMonthDate = habitStartMonth
        
        while currentMonthDate <= currentMonth {
            monthsList.append(currentMonthDate)
            currentMonthDate = calendar.date(byAdding: .month, value: 1, to: currentMonthDate) ?? currentMonthDate
        }
        
        months = monthsList
    }
    
    private func findCurrentMonthIndex() {
        let today = Date()
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: today)
        let currentMonth = calendar.date(from: currentMonthComponents) ?? today
        
        if let index = months.firstIndex(where: { calendar.isDate($0, equalTo: currentMonth, toGranularity: .month) }) {
            currentMonthIndex = index
        } else {
            currentMonthIndex = max(0, months.count - 1)
        }
    }
    
    private func generateChartData() {
        guard !months.isEmpty && currentMonthIndex >= 0 && currentMonthIndex < months.count else {
            chartData = []
            return
        }
        
        let month = currentMonth
        
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            chartData = []
            return
        }
        
        var data: [ChartDataPoint] = []
        
        for day in 1...range.count {
            guard let currentDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) else { continue }
            
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
