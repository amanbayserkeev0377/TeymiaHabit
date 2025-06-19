import SwiftUI

struct HabitHeatmapCard: View {
    let habit: Habit
    let onTap: () -> Void
    
    @State private var heatmapData: [HeatmapDataPoint] = []
    @State private var appeared = false
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header - консистентный с line charts
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
                    
                    // Year stats
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(yearCompletionRate)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(habit.iconColor.color)
                        
                        Text("this_year".localized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16) // Отступы только для хедера
                
                // Heatmap Grid с осями - ЕДИНЫЙ ScrollView
                VStack(alignment: .leading, spacing: 4) {
                    // Weekdays column (фиксированный слева)
                    HStack(alignment: .top, spacing: 4) {
                        // Fixed weekday labels
                        VStack(spacing: 1) {
                            // Empty space for month labels
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 12, height: 16) // Высота под месяцы
                            
                            // Weekday labels
                            ForEach(0..<7, id: \.self) { dayIndex in
                                Text(weekdayLabels[dayIndex])
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 12, height: 12, alignment: .center)
                            }
                        }
                        .frame(width: weekdayLabelWidth)
                        
                        // ЕДИНЫЙ ScrollView для месяцев и heatmap
                        ScrollView(.horizontal, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 1) {
                                // Month labels row - ПО ФАКТУ НЕДЕЛЬ
                                HStack(spacing: 0) {
                                    ForEach(monthLabelsForWeeks, id: \.week) { monthLabel in
                                        Text(monthLabel.name)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .frame(width: CGFloat(monthLabel.weeks) * 13, alignment: .leading)
                                    }
                                }
                                .frame(height: 16)
                                
                                // Heatmap grid
                                HStack(spacing: 1) {
                                    ForEach(Array(yearlyWeeks.enumerated()), id: \.offset) { weekIndex, weekData in
                                        VStack(spacing: 1) {
                                            ForEach(0..<7, id: \.self) { dayIndex in
                                                if dayIndex < weekData.days.count {
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(colorForCompletionRate(weekData.days[dayIndex].completionRate))
                                                        .frame(width: 12, height: 12)
                                                        .opacity(appeared ? 1 : 0)
                                                        .scaleEffect(appeared ? 1 : 0.3)
                                                        .animation(
                                                            .easeOut(duration: 0.4)
                                                            .delay(Double(weekIndex) * 0.01),
                                                            value: appeared
                                                        )
                                                } else {
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(Color.clear)
                                                        .frame(width: 12, height: 12)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                .padding(.horizontal, 8) // Как у line charts
                
                // Legend (GitHub-style)
                HStack {
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text("less".localized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        // 5-level legend squares
                        ForEach(0..<5, id: \.self) { level in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(legendColor(for: level))
                                .frame(width: 12, height: 12)
                        }
                        
                        Text("more".localized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16) // Как header
                .padding(.top, 8)
            }
            .padding(.horizontal, 0)  // Убираем лишние отступы
            .padding(.vertical, 12)   // Только вертикальные отступы
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            generateYearlyHeatmapData()
            // Запускаем анимацию с небольшой задержкой для плавности
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appeared = true
            }
        }
    }
    
    // MARK: - Constants
    
    private let weekdayLabelWidth: CGFloat = 16
    private let monthWidth: CGFloat = 50  // Фиксированная ширина для каждого месяца
    
    // MARK: - Helper Functions
    
    private func monthLabel(for month: Int) -> some View {
        let currentYear = calendar.component(.year, from: Date())
        guard let monthDate = calendar.date(from: DateComponents(year: currentYear, month: month, day: 1)) else {
            return Text("???")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        let fullName = formatter.string(from: monthDate)
        let shortName = String(fullName.prefix(3)).capitalized  // Первая буква заглавная
        
        return Text(shortName)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
    
    private var weekdayLabels: [String] {
        // First letter of weekday names: M T W T F S S
        let firstWeekday = calendar.firstWeekday
        var labels: [String] = []
        
        for i in 0..<7 {
            let weekdayIndex = (firstWeekday + i - 1) % 7
            let weekdayName = calendar.shortWeekdaySymbols[weekdayIndex]
            labels.append(String(weekdayName.prefix(1)).uppercased())
        }
        
        return labels
    }
    
    // MARK: - Data Generation
    
    private func generateYearlyHeatmapData() {
        var data: [HeatmapDataPoint] = []
        
        // Start from January 1st of current year
        let currentYear = calendar.component(.year, from: Date())
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31)) else {
            return
        }
        
        // Generate data for entire year
        var currentDate = startOfYear
        while currentDate <= min(endOfYear, Date()) {
            let completionRate = calculateCompletionRate(for: currentDate)
            data.append(HeatmapDataPoint(date: currentDate, completionRate: completionRate))
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        heatmapData = data
    }
    
    private func calculateCompletionRate(for date: Date) -> Double {
        // Only calculate for dates not in the future
        guard date <= Date() else { return 0 }
        
        // Check if habit is active on this date
        guard habit.isActiveOnDate(date) else { return 0 }
        
        let progress = habit.progressForDate(date)
        let goal = habit.goal
        
        // Return actual completion rate (0.0 to 1.0+)
        let rate = goal > 0 ? Double(progress) / Double(goal) : 0
        return max(0.0, rate) // Allow over 100% completion
    }
    
    private func colorForCompletionRate(_ rate: Double) -> Color {
        let baseColor = habit.iconColor.color
        
        // GitHub-style 5-level intensity system
        switch rate {
        case 0:
            // No activity - light gray
            return Color.gray.opacity(0.1)
        case 0.01..<0.25:
            // Low activity (1-24%) - very light color
            return baseColor.opacity(0.3)
        case 0.25..<0.50:
            // Medium-low activity (25-49%) - light color
            return baseColor.opacity(0.5)
        case 0.50..<0.75:
            // Medium activity (50-74%) - medium color
            return baseColor.opacity(0.7)
        case 0.75..<1.0:
            // High activity (75-99%) - strong color
            return baseColor.opacity(0.9)
        default:
            // Complete/exceeded (100%+) - full intensity
            return baseColor
        }
    }
    
    private func legendColor(for level: Int) -> Color {
        let baseColor = habit.iconColor.color
        
        switch level {
        case 0: return Color.gray.opacity(0.1)      // No activity
        case 1: return baseColor.opacity(0.3)       // Low activity
        case 2: return baseColor.opacity(0.5)       // Medium-low activity
        case 3: return baseColor.opacity(0.7)       // Medium activity
        case 4: return baseColor                     // High activity
        default: return baseColor
        }
    }
    
    // MARK: - Computed Properties
    
    private var yearlyWeeks: [WeekData] {
        // GitHub подход: показываем ровно 52 недели начиная с первой недели года
        var weeks: [WeekData] = []
        let currentYear = calendar.component(.year, from: Date())
        
        // Находим первое воскресенье года (или последнее воскресенье прошлого года)
        guard let january1st = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)) else {
            return []
        }
        
        // Найти начало первой недели (воскресенье)
        var startDate = january1st
        while calendar.component(.weekday, from: startDate) != 1 { // 1 = Sunday
            startDate = calendar.date(byAdding: .day, value: -1, to: startDate)!
        }
        
        // Генерируем ровно 52 недели
        for weekIndex in 0..<52 {
            var weekDays: [HeatmapDataPoint] = []
            
            for dayIndex in 0..<7 {
                let currentDate = calendar.date(byAdding: .day, value: weekIndex * 7 + dayIndex, to: startDate)!
                
                // Если дата в текущем году и не в будущем, берем реальные данные
                let currentDateYear = calendar.component(.year, from: currentDate)
                if currentDateYear == currentYear && currentDate <= Date() {
                    let dataPoint = heatmapData.first { calendar.isDate($0.date, inSameDayAs: currentDate) } ?? 
                                    HeatmapDataPoint(date: currentDate, completionRate: 0)
                    weekDays.append(dataPoint)
                } else {
                    // Пустая ячейка для дат вне текущего года или в будущем
                    weekDays.append(HeatmapDataPoint(date: currentDate, completionRate: 0))
                }
            }
            
            weeks.append(WeekData(week: weekIndex, days: weekDays))
        }
        
        return weeks
    }
    
    private var monthLabelsForWeeks: [MonthLabelInfo] {
        let weeks = yearlyWeeks
        var monthLabels: [MonthLabelInfo] = []
        var currentMonth = -1
        var weekCount = 0
        
        for week in weeks {
            // Берем средний день недели для определения месяца
            let middleDay = week.days[3] // Среда
            let monthOfWeek = calendar.component(.month, from: middleDay.date)
            let yearOfWeek = calendar.component(.year, from: middleDay.date)
            
            // Показываем только месяцы текущего года
            guard yearOfWeek == calendar.component(.year, from: Date()) else {
                continue
            }
            
            if monthOfWeek != currentMonth {
                // Сохраняем предыдущий месяц
                if currentMonth > 0 && weekCount > 0 {
                    if let monthDate = calendar.date(from: DateComponents(year: yearOfWeek, month: currentMonth, day: 1)) {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "LLLL"
                        let fullName = formatter.string(from: monthDate)
                        let shortName = String(fullName.prefix(3)).capitalized
                        
                        monthLabels.append(MonthLabelInfo(name: shortName, weeks: weekCount, week: monthLabels.count))
                    }
                }
                
                // Начинаем новый месяц
                currentMonth = monthOfWeek
                weekCount = 1
            } else {
                weekCount += 1
            }
        }
        
        // Не забываем последний месяц
        if currentMonth > 0 && weekCount > 0 {
            let currentYear = calendar.component(.year, from: Date())
            if let monthDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1)) {
                let formatter = DateFormatter()
                formatter.dateFormat = "LLLL"
                let fullName = formatter.string(from: monthDate)
                let shortName = String(fullName.prefix(3)).capitalized
                
                monthLabels.append(MonthLabelInfo(name: shortName, weeks: weekCount, week: monthLabels.count))
            }
        }
        
        return monthLabels
    }
    
    private var yearCompletionRate: String {
        let activeDays = heatmapData.filter { dataPoint in
            habit.isActiveOnDate(dataPoint.date) && dataPoint.date <= Date()
        }
        
        if activeDays.isEmpty { return "0%" }
        
        let completedDays = activeDays.filter { $0.completionRate >= 1.0 }.count
        let percentage = (Double(completedDays) / Double(activeDays.count)) * 100
        return "\(Int(percentage))%"
    }
}
