import SwiftUI
import SwiftData

enum CalendarAction {
    case complete, addProgress, resetProgress
}

struct MonthlyCalendarView: View {
    // MARK: - Properties
    let habit: Habit
    
    var updateCounter: Int = 0
    var onActionRequested: (CalendarAction, Date) -> Void = { _, _ in }
    var onCountInput: ((Int, Date) -> Void)?
    var onTimeInput: ((Int, Int, Date) -> Void)?
    
    @Binding var selectedDate: Date
    @Binding var showingCountInput: Bool
    @Binding var showingTimeInput: Bool
    
    @Environment(\.modelContext) private var modelContext
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    
    // MARK: - State
    @State private var selectedActionDate: Date?
    @State private var showingActionSheet = false
    @State private var months: [Date] = []
    @State private var currentMonthIndex: Int = 0
    @State private var monthCalendarCache: [Int: [[Date?]]] = [:]
    
    @Query private var completions: [HabitCompletion]
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    // MARK: - Initialization
    init(
        habit: Habit,
        selectedDate: Binding<Date>,
        updateCounter: Int = 0,
        onActionRequested: @escaping (CalendarAction, Date) -> Void = { _, _ in },
        showingCountInput: Binding<Bool>,
        showingTimeInput: Binding<Bool>,
        onCountInput: ((Int, Date) -> Void)? = nil,
        onTimeInput: ((Int, Int, Date) -> Void)? = nil
    ) {
        self.habit = habit
        self._selectedDate = selectedDate
        self.updateCounter = updateCounter
        self.onActionRequested = onActionRequested
        self._showingCountInput = showingCountInput
        self._showingTimeInput = showingTimeInput
        self.onCountInput = onCountInput
        self.onTimeInput = onTimeInput
        
        let habitId = habit.id
        let habitPredicate = #Predicate<HabitCompletion> { completion in
            completion.habit?.id == habitId
        }
        self._completions = Query(filter: habitPredicate)
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            monthNavigationHeader
            
            weekdayHeader
            
            if !months.isEmpty {
                monthGridContainer
            }
        }
        .onAppear(perform: setupCalendar)
        .onChange(of: selectedDate) { _, newDate in
            updateMonthIfNeeded(for: newDate)
        }
        .onChange(of: updateCounter) { _, _ in
            regenerateAllCalendarDays()
        }
        .onChange(of: weekdayPrefs.firstDayOfWeek) { _, _ in
            regenerateAllCalendarDays()
        }
        .confirmationDialog(
            dialogTitle,
            isPresented: $showingActionSheet,
            titleVisibility: .visible
        ) {
            actionSheetButtons
        }
    }
    
    // MARK: - Components
    private var monthNavigationHeader: some View {
        HStack {
            Button(action: showPreviousMonth) {
                Image("chevron.left")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(canNavigateToPreviousMonth ? .primary : Color.gray.opacity(0.5))
                    .contentShape(Rectangle())
            }
            .disabled(!canNavigateToPreviousMonth)
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(DateFormatter.capitalizedNominativeMonthYear(from: currentMonth))
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
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .zIndex(1)
    }
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                Text(calendar.orderedWeekdayInitials[index])
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 16)
    }
    
    private var monthGridContainer: some View {
        TabView(selection: $currentMonthIndex) {
            ForEach(months.indices, id: \.self) { index in
                monthGrid(forIndex: index)
                    .frame(height: 280)
                    .tag(index)
                    .onAppear {
                        // Cache when view appears (safe place to modify state)
                        cacheCalendarDays(for: index)
                    }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 280)
        .onAppear {
            generateCalendarDaysIfNeeded(for: currentMonthIndex)
        }
        .onChange(of: currentMonthIndex) { oldValue, newValue in
            generateCalendarDaysIfNeeded(for: newValue)
            
            // Preload adjacent months
            if newValue > 0 {
                generateCalendarDaysIfNeeded(for: newValue - 1)
            }
            if newValue < months.count - 1 {
                generateCalendarDaysIfNeeded(for: newValue + 1)
            }
        }
    }
    
    private var actionSheetButtons: some View {
        Group {
            Button("complete".localized) {
                if let date = selectedActionDate {
                    onActionRequested(.complete, date)
                }
            }
            
            Button("add_progress".localized) {
                if let date = selectedActionDate {
                    if habit.type == .count {
                        showingCountInput = true
                    } else {
                        showingTimeInput = true
                    }
                    onActionRequested(.addProgress, date)
                }
            }
            
            Button(role: .destructive) {
                if let date = selectedActionDate {
                    onActionRequested(.resetProgress, date)
                }
            } label: {
                Text("button_reset_progress".localized)
            }
        }
    }
    
    private func monthGrid(forIndex index: Int) -> some View {
        // Get or generate calendar days for this month
        let days = getCalendarDays(for: index)
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 7) {
            ForEach(0..<days.count, id: \.self) { row in
                ForEach(0..<7, id: \.self) { column in
                    if let date = days[row][column] {
                        let isActiveDate = date <= Date() && date >= habit.startDate && habit.isActiveOnDate(date)
                        let progress = habit.completionPercentageForDate(date)
                        
                        DayProgressItem(
                            date: date,
                            isSelected: calendar.isDate(selectedDate, inSameDayAs: date),
                            progress: progress,
                            onTap: {
                                selectedDate = date
                                if isActiveDate {
                                    selectedActionDate = date
                                    showingActionSheet = true
                                }
                            },
                            showProgressRing: isActiveDate,
                            habit: habit
                        )
                        .frame(width: 40, height: 40)
                        .buttonStyle(BorderlessButtonStyle())
                        .popover(isPresented: Binding(
                            get: { showingCountInput && calendar.isDate(date, inSameDayAs: selectedActionDate ?? Date.distantPast) },
                            set: { if !$0 { showingCountInput = false } }
                        )) {
                            CountInputPopover(habit: habit) { count in
                                onCountInput?(count, date)
                            }
                        }
                        .popover(isPresented: Binding(
                            get: { showingTimeInput && calendar.isDate(date, inSameDayAs: selectedActionDate ?? Date.distantPast) },
                            set: { if !$0 { showingTimeInput = false } }
                        )) {
                            TimeInputPopover(habit: habit) { hours, minutes in
                                onTimeInput?(hours, minutes, date)
                            }
                        }
                    } else {
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Computed Properties
    private var dialogTitle: String {
        guard let selectedActionDate = selectedActionDate else { return "" }
        
        let dateString = dateFormatter.string(from: selectedActionDate)
        let progressFormatted = habit.formattedProgress(for: selectedActionDate)
        let goalFormatted = habit.formattedGoal
        
        return "\(dateString)\n\(progressFormatted) / \(goalFormatted)"
    }
    
    private var currentMonth: Date {
        guard !months.isEmpty, currentMonthIndex >= 0, currentMonthIndex < months.count else {
            return Date()
        }
        return months[currentMonthIndex]
    }
    
    private var canNavigateToPreviousMonth: Bool {
        currentMonthIndex > 0
    }
    
    private var canNavigateToNextMonth: Bool {
        guard !months.isEmpty else { return false }
        
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: Date())
        let displayedMonthComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        
        return !(displayedMonthComponents.year! > currentMonthComponents.year! ||
                 (displayedMonthComponents.year! == currentMonthComponents.year! &&
                  displayedMonthComponents.month! >= currentMonthComponents.month!))
    }
    
    // MARK: - Setup Methods
    private func setupCalendar() {
        generateMonths()
        findCurrentMonthIndex()
        // Generate initial months
        generateCalendarDaysIfNeeded(for: currentMonthIndex)
    }
    
    private func updateMonthIfNeeded(for newDate: Date) {
        if let monthIndex = findMonthIndex(for: newDate) {
            if monthIndex != currentMonthIndex {
                currentMonthIndex = monthIndex
            }
        }
    }
    
    // MARK: - Calendar Generation
    private func generateMonths() {
        let today = Date()
        let effectiveStartDate = HistoryLimits.limitStartDate(habit.startDate)
        
        let startComponents = calendar.dateComponents([.year, .month], from: effectiveStartDate)
        let todayComponents = calendar.dateComponents([.year, .month], from: today)
        
        guard let startMonth = calendar.date(from: startComponents),
              let currentMonth = calendar.date(from: todayComponents) else {
            months = [today]
            return
        }
        
        var generatedMonths: [Date] = []
        var currentDate = startMonth
        
        while currentDate <= currentMonth {
            generatedMonths.append(currentDate)
            
            guard let nextMonth = calendar.date(byAdding: DateComponents(month: 1), to: currentDate) else {
                break
            }
            currentDate = nextMonth
        }
        
        if generatedMonths.isEmpty {
            generatedMonths = [currentMonth]
        }
        
        months = generatedMonths
    }
    
    // Get calendar days for a month, generating if needed
    private func getCalendarDays(for index: Int) -> [[Date?]] {
        if let cached = monthCalendarCache[index] {
            return cached
        }
        
        // Generate if not cached, but DON'T save during view render
        guard index >= 0, index < months.count else {
            return []
        }
        
        return generateCalendarDays(for: months[index])
    }

    // Save to cache (call this in onChange/onAppear, not during render)
    private func cacheCalendarDays(for index: Int) {
        guard index >= 0, index < months.count, monthCalendarCache[index] == nil else {
            return
        }
        
        let days = generateCalendarDays(for: months[index])
        monthCalendarCache[index] = days
    }

    // Check if calendar days need generation
    private func generateCalendarDaysIfNeeded(for index: Int) {
        guard index >= 0, index < months.count, monthCalendarCache[index] == nil else {
            return
        }
        
        let days = generateCalendarDays(for: months[index])
        monthCalendarCache[index] = days
    }
    
    // Regenerate all cached months (when updateCounter or weekday changes)
    private func regenerateAllCalendarDays() {
        monthCalendarCache.removeAll()
        // Regenerate current and adjacent months
        generateCalendarDaysIfNeeded(for: currentMonthIndex)
        if currentMonthIndex > 0 {
            generateCalendarDaysIfNeeded(for: currentMonthIndex - 1)
        }
        if currentMonthIndex < months.count - 1 {
            generateCalendarDaysIfNeeded(for: currentMonthIndex + 1)
        }
    }
    
    private func generateCalendarDays(for month: Date) -> [[Date?]] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else {
            return []
        }
        let numDays = range.count
        
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        var firstWeekday = calendar.component(.weekday, from: firstDay) - calendar.firstWeekday
        if firstWeekday < 0 {
            firstWeekday += 7
        }
        
        var days: [[Date?]] = []
        var week: [Date?] = Array(repeating: nil, count: 7)
        
        // Fill first week
        for day in 0..<min(7, numDays + firstWeekday) {
            if day >= firstWeekday {
                let dayOffset = day - firstWeekday
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDay) {
                    week[day] = date
                }
            }
        }
        days.append(week)
        
        // Fill remaining weeks
        let remainingDays = numDays - (7 - firstWeekday)
        let remainingWeeks = (remainingDays + 6) / 7
        
        for weekNum in 0..<remainingWeeks {
            week = Array(repeating: nil, count: 7)
            
            for dayOfWeek in 0..<7 {
                let day = 7 - firstWeekday + weekNum * 7 + dayOfWeek + 1
                if day <= numDays {
                    if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                        week[dayOfWeek] = date
                    }
                }
            }
            
            days.append(week)
        }
        
        return days
    }
    
    // MARK: - Helper Methods
    private func findMonthIndex(for date: Date) -> Int? {
        let targetComponents = calendar.dateComponents([.year, .month], from: date)
        
        for (index, month) in months.enumerated() {
            let monthComponents = calendar.dateComponents([.year, .month], from: month)
            if monthComponents.year == targetComponents.year && monthComponents.month == targetComponents.month {
                return index
            }
        }
        
        return nil
    }
    
    private func findCurrentMonthIndex() {
        if let index = findMonthIndex(for: selectedDate) {
            currentMonthIndex = index
        } else if !months.isEmpty {
            currentMonthIndex = months.count - 1
        }
    }
    
    // MARK: - Navigation Actions
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
    
    // MARK: - Formatters
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
