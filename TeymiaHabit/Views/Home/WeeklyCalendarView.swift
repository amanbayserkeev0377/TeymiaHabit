import SwiftUI
import SwiftData

struct WeeklyCalendarView: View {
    @Binding var selectedDate: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(WeekdayPreferences.self) private var weekdayPrefs

    @Query private var habits: [Habit]
    @Query private var allCompletions: [HabitCompletion]

    @State private var weeks: [[Date]] = []
    @State private var currentWeekIndex: Int = 0
    @State private var progressData: [Date: Double] = [:]
    @State private var availableDateRange: ClosedRange<Date>?

    private var calendar: Calendar {
        Calendar.userPreferred
    }

    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate

        let sortDescriptor = SortDescriptor<Habit>(\.createdAt, order: .forward)
        _habits = Query(sort: [sortDescriptor])

        let completionSort = SortDescriptor<HabitCompletion>(\.date, order: .reverse)
        _allCompletions = Query(sort: [completionSort])
    }

    var body: some View {
        TabView(selection: $currentWeekIndex) {
            ForEach(Array(weeks.enumerated()), id: \.element.first) { index, week in
                HStack(spacing: 16) {
                    ForEach(week, id: \.self) { date in
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
        .onChange(of: completionsData) { _, _ in
            loadProgressData()
        }
    }

    // MARK: - Derived Data

    private var habitsData: [String] {
        habits.map { "\($0.startDate.timeIntervalSince1970)-\($0.isArchived)" }
    }

    private var completionsData: [String] {
        allCompletions.map { "\($0.date.timeIntervalSince1970)-\($0.value)-\($0.habit?.id ?? "")" }
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

    private func handleHabitsDataChange() {
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

    // MARK: - Date Utilities

    private func calculateAvailableDateRange() {
        let activeHabits = habits.filter { !$0.isArchived }

        guard !activeHabits.isEmpty else {
            availableDateRange = nil
            return
        }

        let today = Date()
        let earliestStartDate = activeHabits.map { $0.startDate }.min() ?? today
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

        return habits.contains {
            !$0.isArchived && $0.isActiveOnDate(date) && date >= $0.startDate
        }
    }

    // MARK: - Week Generation

    private func generateWeeks() {
        guard let dateRange = availableDateRange else {
            weeks = []
            return
        }

        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound

        var weekStartComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)
        guard let weekStart = calendar.date(from: weekStartComponents) else {
            weeks = []
            return
        }

        weekStartComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: endDate)
        guard let lastWeekStart = calendar.date(from: weekStartComponents),
              let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: lastWeekStart) else {
            weeks = []
            return
        }

        var generatedWeeks: [[Date]] = []
        var currentWeekStart = weekStart

        while currentWeekStart < weekEnd {
            let weekDates = (0..<7).compactMap {
                calendar.date(byAdding: .day, value: $0, to: currentWeekStart)
            }

            if !weekDates.isEmpty {
                generatedWeeks.append(weekDates)
            }

            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else {
                break
            }

            currentWeekStart = nextWeek
        }

        weeks = generatedWeeks
    }

    // MARK: - Progress Calculation

    private func loadProgressData() {
        guard !weeks.isEmpty, currentWeekIndex < weeks.count else { return }

        let week = weeks[currentWeekIndex]
        var newProgressData: [Date: Double] = [:]

        for date in week where hasActiveHabits(for: date) {
            newProgressData[date] = calculateProgress(for: date)
        }

        for (date, progress) in newProgressData {
            progressData[date] = progress
        }
    }

    private func calculateProgress(for date: Date) -> Double {
        let activeHabits = habits.filter {
            !$0.isArchived && $0.isActiveOnDate(date) && date >= $0.startDate
        }

        guard !activeHabits.isEmpty else { return 0 }

        let total = activeHabits.reduce(0.0) {
            $0 + $1.completionPercentageForDate(date)
        }

        return total / Double(activeHabits.count)
    }

    // MARK: - Week Navigation

    private func findCurrentWeekIndex() {
        if let index = findWeekIndex(for: selectedDate) {
            withAnimation {
                currentWeekIndex = index
            }
        } else if !weeks.isEmpty {
            withAnimation {
                currentWeekIndex = weeks.count - 1
            }
        }
    }

    private func findWeekIndex(for date: Date) -> Int? {
        weeks.firstIndex {
            $0.contains { calendar.isDate($0, inSameDayAs: date) }
        }
    }
}
