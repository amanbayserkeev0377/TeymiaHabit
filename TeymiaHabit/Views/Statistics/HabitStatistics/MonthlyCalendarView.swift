import SwiftUI
import SwiftData

enum CalendarAction {
    case complete, addProgress, resetProgress
}

struct MonthlyCalendarView: View {
    // MARK: - Properties
    let habit: Habit
    @Binding var selectedDate: Date
    
    var updateCounter: Int = 0
    var onActionRequested: (CalendarAction, Date) -> Void = { _, _ in }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    
    // MARK: - State
    @State private var selectedActionDate: Date?
    @State private var showingActionSheet = false
    @State private var months: [Date] = []
    @State private var currentMonthIndex: Int = 0
    @State private var calendarDays: [[Date?]] = []
    @State private var isLoading: Bool = false
    
    @Query private var completions: [HabitCompletion]
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    // MARK: - Initialization
    init(habit: Habit, selectedDate: Binding<Date>, updateCounter: Int = 0, onActionRequested: @escaping (CalendarAction, Date) -> Void = { _, _ in }) {
        self.habit = habit
        self._selectedDate = selectedDate
        self.updateCounter = updateCounter
        self.onActionRequested = onActionRequested
        
        let habitId = habit.id
        let habitPredicate = #Predicate<HabitCompletion> { completion in
            completion.habit?.id == habitId
        }
        self._completions = Query(filter: habitPredicate)
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 10) {
            monthNavigationHeader
                .padding(.bottom)
            weekdayHeader
            
            if isLoading {
                ProgressView()
                    .frame(height: 250)
            } else if months.isEmpty || calendarDays.isEmpty {
                Text("loading_calendar".localized)
                    .frame(height: 250)
            } else {
                monthGridContainer
            }
        }
        .padding(.vertical)
        .padding(.horizontal, 5)
        .onAppear(perform: setupCalendar)
        .onChange(of: selectedDate) { _, newDate in
            updateMonthIfNeeded(for: newDate)
        }
        .onChange(of: updateCounter) { _, _ in
            generateCalendarDays()
        }
        .onChange(of: weekdayPrefs.firstDayOfWeek) { _, _ in
            generateCalendarDays()
        }
        .confirmationDialog(
            Text(dialogTitle)
                .fontDesign(.rounded),
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
                .fontDesign(.rounded)
                .fontWeight(.medium)
            
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
        .padding(.horizontal, 8)
        .zIndex(1)
    }
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                Text(calendar.orderedWeekdayInitials[index])
                    .font(.caption)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
    private var monthGridContainer: some View {
        VStack {
            monthGrid(forMonth: currentMonth)
                .frame(height: min(CGFloat(calendarDays.count) * 55, 300))
                .id("month-\(currentMonthIndex)-\(updateCounter)")
                .gesture(swipeGesture)
        }
        .background(Color.clear)
    }
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                let horizontalDistance = value.translation.width
                let verticalDistance = abs(value.translation.height)
                
                if abs(horizontalDistance) > verticalDistance * 2 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if horizontalDistance > 0 && canNavigateToPreviousMonth {
                            showPreviousMonth()
                        } else if horizontalDistance < 0 && canNavigateToNextMonth {
                            showNextMonth()
                        }
                    }
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
    
    private func monthGrid(forMonth month: Date) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
            ForEach(0..<calendarDays.count, id: \.self) { row in
                ForEach(0..<7, id: \.self) { column in
                    if let date = calendarDays[row][column] {
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
                        .id("\(row)-\(column)-\(date.timeIntervalSince1970)-\(progress)-\(updateCounter)")
                        .buttonStyle(BorderlessButtonStyle())
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
        months.isEmpty ? Date() : months[currentMonthIndex]
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
        isLoading = true
        generateMonths()
        findCurrentMonthIndex()
        generateCalendarDays()
        isLoading = false
    }
    
    private func updateMonthIfNeeded(for newDate: Date) {
        if let monthIndex = findMonthIndex(for: newDate) {
            if monthIndex != currentMonthIndex {
                currentMonthIndex = monthIndex
                generateCalendarDays()
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
    
    private func generateCalendarDays() {
        guard !months.isEmpty && currentMonthIndex < months.count else {
            calendarDays = []
            return
        }
        
        let month = months[currentMonthIndex]
        
        guard let range = calendar.range(of: .day, in: .month, for: month) else {
            calendarDays = []
            return
        }
        let numDays = range.count
        
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            calendarDays = []
            return
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
        
        calendarDays = days
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
        currentMonthIndex -= 1
        generateCalendarDays()
    }
    
    private func showNextMonth() {
        guard canNavigateToNextMonth else { return }
        currentMonthIndex += 1
        generateCalendarDays()
    }
    
    // MARK: - Formatters
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
