import SwiftUI
import SwiftData

struct WeeklyCalendarView: View {
    @Binding var selectedDate: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    
    @Query private var habits: [Habit]
    
    @State private var weeks: [[Date]] = []
    @State private var currentWeekIndex: Int = 0
    @State private var progressData: [Date: Double] = [:]
    @State private var availableDateRange: ClosedRange<Date>?
    
    private var calendar: Calendar {
        return Calendar.userPreferred
    }
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        
        let sortDescriptor = SortDescriptor<Habit>(\.createdAt, order: .forward)
        _habits = Query(sort: [sortDescriptor])
    }
    
    var body: some View {
        TabView(selection: $currentWeekIndex) {
            ForEach(Array(weeks.enumerated()), id: \.element.first) { index, week in
                HStack(spacing: 16) {
                    ForEach(week, id: \.self) { date in
                        // Разбиваем сложные вычисления на простые переменные
                        let hasHabits = hasActiveHabits(for: date)
                        let isAvailable = isDateInAvailableRange(date)
                        let isSelected = calendar.isDate(selectedDate, inSameDayAs: date)
                        let progress = hasHabits ? (progressData[date] ?? 0) : 0
                        let showRing = hasHabits && isAvailable
                        
                        DayProgressItem(
                            date: date,
                            isSelected: isSelected,
                            progress: progress,
                            onTap: {
                                handleDateTap(date: date, hasHabits: hasHabits, isAvailable: isAvailable)
                            },
                            showProgressRing: showRing,
                            isOverallProgress: true
                        )
                        .frame(width: 35)
                    }
                }
                .padding(.horizontal, 16)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 55)
        .onChange(of: currentWeekIndex) { _, _ in
            loadProgressData()
        }
        .onAppear {
            calculateAvailableDateRange()
            generateWeeks()
            loadProgressData()
            findCurrentWeekIndex()
        }
        .onChange(of: selectedDate) { _, newDate in
            handleSelectedDateChange(newDate)
        }
        .onChange(of: weekdayPrefs.firstDayOfWeek) { _, _ in
            handleWeekdayPrefsChange()
        }
        .onChange(of: habitsData) { _, _ in
            handleHabitsDataChange()
        }
    }
    
    // MARK: - Computed Properties
    
    // Упрощаем отслеживание изменений в привычках
    private var habitsData: [String] {
        habits.map { "\($0.startDate.timeIntervalSince1970)-\($0.isArchived)" }
    }
    
    // MARK: - Event Handlers
    
    private func handleDateTap(date: Date, hasHabits: Bool, isAvailable: Bool) {
        if hasHabits && isAvailable {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDate = date
            }
        }
    }
    
    private func handleSelectedDateChange(_ newDate: Date) {
        if let weekIndex = findWeekIndex(for: newDate) {
            withAnimation {
                currentWeekIndex = weekIndex
            }
        }
    }
    
    private func handleHabitsUpdate() {
        calculateAvailableDateRange()
        generateWeeks()
        loadProgressData()
        findCurrentWeekIndex()
    }
    
    private func handleWeekdayPrefsChange() {
        weeks = []
        calculateAvailableDateRange()
        generateWeeks()
        findCurrentWeekIndex()
        loadProgressData()
    }
    
    private func handleHabitsDataChange() {
        calculateAvailableDateRange()
        generateWeeks()
        loadProgressData()
        findCurrentWeekIndex()
    }
    
    // MARK: - Smart Date Range Calculation
    
    private func calculateAvailableDateRange() {
        let activeHabits = habits.filter { !$0.isArchived }
        
        guard !activeHabits.isEmpty else {
            availableDateRange = nil
            return
        }
        
        let today = Date()
        let earliestStartDate = activeHabits.map { $0.startDate }.min() ?? today
        
        // Ограничиваем максимум 1 год назад от сегодня (для серьезных пользователей)
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today) ?? today
        let effectiveStartDate = max(earliestStartDate, oneYearAgo)
        
        availableDateRange = effectiveStartDate...today
    }
    
    private func isDateInAvailableRange(_ date: Date) -> Bool {
        guard let range = availableDateRange else { return false }
        return range.contains(date)
    }
    
    private func hasActiveHabits(for date: Date) -> Bool {
        guard isDateInAvailableRange(date) else { return false }
        
        let activeHabits = habits.filter { habit in
            !habit.isArchived &&
            habit.isActiveOnDate(date) &&
            date >= habit.startDate
        }
        
        return !activeHabits.isEmpty
    }
    
    // MARK: - Week Generation (Smart)
    
    private func generateWeeks() {
        guard let dateRange = availableDateRange else {
            weeks = []
            return
        }
        
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        
        // Находим начало недели для первой даты с учетом пользовательских настроек
        var weekStartComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)
        guard let weekStart = calendar.date(from: weekStartComponents) else {
            weeks = []
            return
        }
        
        // Находим конец недели для последней даты
        weekStartComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: endDate)
        guard let lastWeekStart = calendar.date(from: weekStartComponents),
              let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: lastWeekStart) else {
            weeks = []
            return
        }
        
        var generatedWeeks: [[Date]] = []
        var currentWeekStart = weekStart
        
        while currentWeekStart < weekEnd {
            var weekDates: [Date] = []
            
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart) {
                    weekDates.append(date)
                }
            }
            
            if !weekDates.isEmpty {
                generatedWeeks.append(weekDates)
            }
            
            // Переходим к следующей неделе
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else {
                break
            }
            currentWeekStart = nextWeek
        }
        
        weeks = generatedWeeks
    }
    
    // MARK: - Progress Calculation
    
    private func loadProgressData() {
        if !weeks.isEmpty && currentWeekIndex < weeks.count {
            let week = weeks[currentWeekIndex]
            var newProgressData: [Date: Double] = [:]
            
            for date in week {
                if hasActiveHabits(for: date) {
                    let progress = calculateProgress(for: date)
                    newProgressData[date] = progress
                }
            }
            
            // Обновляем все значения сразу
            for (date, progress) in newProgressData {
                progressData[date] = progress
            }
        }
    }
    
    private func calculateProgress(for date: Date) -> Double {
        let activeHabits = habits.filter { habit in
            !habit.isArchived &&
            habit.isActiveOnDate(date) &&
            date >= habit.startDate
        }
        
        guard !activeHabits.isEmpty else { return 0 }
        
        let totalCompletionPercentage = activeHabits.reduce(0.0) { total, habit in
            total + habit.completionPercentageForDate(date)
        }
        
        let averageProgress = totalCompletionPercentage / Double(activeHabits.count)
        
        // DEBUG для всех вызовов
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
//        print("📅 calculateProgress: \(formatter.string(from: date)) = \(averageProgress)")
        
        return averageProgress
    }
    
    // MARK: - Navigation
    
    private func findCurrentWeekIndex() {
        if let index = findWeekIndex(for: selectedDate) {
            withAnimation {
                currentWeekIndex = index
            }
        } else if !weeks.isEmpty {
            // Если выбранная дата не найдена, переходим к последней неделе (сегодня)
            withAnimation {
                currentWeekIndex = weeks.count - 1
            }
        }
    }
    
    private func findWeekIndex(for date: Date) -> Int? {
        guard !weeks.isEmpty else { return nil }
        
        for (index, week) in weeks.enumerated() {
            if week.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
                return index
            }
        }
        return nil
    }
}
