import Foundation
import SwiftData

// MARK: - 1. Основной класс Habit (только базовые свойства и инициализаторы)

@Model
final class Habit {
    
    var uuid: UUID = UUID()
    
    // Basic properties
    var title: String = ""
    var type: HabitType = HabitType.count
    var goal: Int = 1
    var iconName: String? = "checkmark"
    var iconColor: HabitIconColor = HabitIconColor.primary
    
    // Archive functionality
    var isArchived: Bool = false
    
    // System properties
    var createdAt: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]?
    
    // Settings for days and reminders
    var activeDaysBitmask: Int = 0b1111111
    
    @Attribute(.externalStorage)
    private var reminderTimesData: Data?
    
    var startDate: Date = Date()
    var displayOrder: Int = 0
    
    // ✅ Computed property для работы с reminderTimes
    var reminderTimes: [Date]? {
        get {
            guard let data = reminderTimesData else { return nil }
            return try? JSONDecoder().decode([Date].self, from: data)
        }
        set {
            if let times = newValue, !times.isEmpty {
                reminderTimesData = try? JSONEncoder().encode(times)
            } else {
                reminderTimesData = nil
            }
        }
    }
    
    // Computed property for compatibility with existing UI
    var activeDays: [Bool] {
        get {
            let orderedWeekdays = Weekday.orderedByUserPreference
            return orderedWeekdays.map { isActive(on: $0) }
        }
        set {
            let orderedWeekdays = Weekday.orderedByUserPreference
            activeDaysBitmask = 0
            for (index, isActive) in newValue.enumerated() where index < 7 {
                if isActive {
                    let weekday = orderedWeekdays[index]
                    setActive(true, for: weekday)
                }
            }
        }
    }
    
    // MARK: - Инициализаторы остаются в основном классе
    
    init(
        title: String = "",
        type: HabitType = .count,
        goal: Int = 1,
        iconName: String? = "checkmark",
        iconColor: HabitIconColor = .primary,
        createdAt: Date = Date(),
        activeDays: [Bool]? = nil,
        reminderTimes: [Date]? = nil,
        startDate: Date = Date()
    ) {
        self.uuid = UUID()
        self.title = title
        self.type = type
        self.goal = goal
        self.iconName = iconName
        self.iconColor = iconColor
        self.createdAt = createdAt
        self.completions = []
        
        if let days = activeDays {
            let orderedWeekdays = Weekday.orderedByUserPreference
            var bitmask = 0
            for (index, isActive) in days.enumerated() where index < 7 {
                if isActive {
                    let weekday = orderedWeekdays[index]
                    bitmask |= (1 << weekday.rawValue)
                }
            }
            self.activeDaysBitmask = bitmask
        } else {
            self.activeDaysBitmask = Habit.createDefaultActiveDaysBitMask()
        }
        
        self.reminderTimes = reminderTimes
        self.startDate = Calendar.current.startOfDay(for: startDate)
    }
    
    func update(
        title: String,
        type: HabitType,
        goal: Int,
        iconName: String?,
        iconColor: HabitIconColor = .primary,
        activeDays: [Bool],
        reminderTimes: [Date]?,
        startDate: Date
    ) {
        self.title = title
        self.type = type
        self.goal = goal
        self.iconName = iconName
        self.iconColor = iconColor
        self.activeDays = activeDays
        self.reminderTimes = reminderTimes
        self.startDate = startDate
    }
    
    // MARK: - Базовые helper методы остаются здесь
    
    static func createDefaultActiveDaysBitMask() -> Int {
        return 0b1111111
    }
    
    var id: String {
        return uuid.uuidString
    }
}

// MARK: - 2. Extension для работы с активными днями

extension Habit {
    
    func isActive(on weekday: Weekday) -> Bool {
        return (activeDaysBitmask & (1 << weekday.rawValue)) != 0
    }
    
    func setActive(_ active: Bool, for weekday: Weekday) {
        if active {
            activeDaysBitmask |= (1 << weekday.rawValue)
        } else {
            activeDaysBitmask &= ~(1 << weekday.rawValue)
        }
    }
    
    func isActiveOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.userPreferred
        
        let dateStartOfDay = calendar.startOfDay(for: date)
        let startDateOfDay = calendar.startOfDay(for: startDate)
        
        if dateStartOfDay < startDateOfDay {
            return false
        }
        
        let weekday = Weekday.from(date: date)
        return isActive(on: weekday)
    }
}

// MARK: - 3. Extension для работы с напоминаниями

extension Habit {
    
    /// Проверка наличия напоминаний
    var hasReminders: Bool {
        return reminderTimes != nil && !(reminderTimes?.isEmpty ?? true)
    }
}

// MARK: - 4. Extension для работы с прогрессом (✅ ПЕРЕНЕСЕНО СЮДА)

extension Habit {
    
    /// Получить прогресс для конкретной даты
    func progressForDate(_ date: Date) -> Int {
        guard let completions = completions else { return 0 }
        
        let calendar = Calendar.current
        let filteredCompletions = completions.filter { calendar.isDate($0.date, inSameDayAs: date) }
        
        let total = filteredCompletions.reduce(0) { $0 + $1.value }
        return total
    }
    
    /// Форматирует любое значение прогресса (единая логика форматирования)
    func formatProgress(_ progress: Int) -> String {
        switch type {
        case .count:
            return "\(progress)"
        case .time:
            return progress.formattedAsTime()
        }
    }
    
    /// Форматированный прогресс для конкретной даты (использует данные из базы)
    func formattedProgress(for date: Date) -> String {
        let progress = progressForDate(date)
        return formatProgress(progress)
    }
    
    /// Live-прогресс с учетом активных таймеров
    @MainActor
    func liveProgress(for date: Date) -> Int {
        // Live прогресс для активных таймеров сегодня
        if type == .time && Calendar.current.isDateInToday(date) {
            let habitId = uuid.uuidString
            if TimerService.shared.isTimerRunning(for: habitId),
               let liveProgress = TimerService.shared.getLiveProgress(for: habitId) {
                return liveProgress
            }
        }
        
        // Обычный прогресс из базы
        return progressForDate(date)
    }
    
    /// Отформатированный live-прогресс
    @MainActor
    func formattedLiveProgress(for date: Date) -> String {
        let progress = liveProgress(for: date)
        return formatProgress(progress)
    }
    
    /// Проверить, выполнена ли привычка на дату
    func isCompletedForDate(_ date: Date) -> Bool {
        return progressForDate(date) >= goal
    }
    
    /// Проверить, превышена ли цель на дату
    func isExceededForDate(_ date: Date) -> Bool {
        return progressForDate(date) > goal
    }
    
    /// Процент выполнения для даты
    func completionPercentageForDate(_ date: Date) -> Double {
        let progress = min(progressForDate(date), 999999)
        
        if goal <= 0 {
            return progress > 0 ? 1.0 : 0.0
        }
        
        let percentage = Double(progress) / Double(goal)
        return min(percentage, 1.0) // Cap at 100%
    }
    
    /// Добавить прогресс
    func addProgress(_ value: Int, for date: Date = .now) {
        let completion = HabitCompletion(date: date, value: value, habit: self)
        
        if completions == nil {
            completions = []
        }
        completions?.append(completion)
    }
}

// MARK: - 5. Extension для работы с форматированными целями

extension Habit {
    
    /// Formatted goal with automatic localization
    /// Uses DateComponentsFormatter for proper i18n (1h → 1ч → 1時間)
    var formattedGoal: String {
        switch type {
        case .count:
            return "\(goal)"
        case .time:
            return goal.formattedAsLocalizedDuration()
        }
    }
}

// MARK: - 6. Extension для операций с ModelContext (SwiftData операции)

extension Habit {
    
    func updateProgress(to newValue: Int, for date: Date, modelContext: ModelContext) {
        if let existingCompletions = completions?.filter({
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }) {
            for completion in existingCompletions {
                modelContext.delete(completion)
            }
        }
        
        if newValue > 0 {
            let completion = HabitCompletion(
                date: date,
                value: newValue,
                habit: self
            )
            modelContext.insert(completion)
        }
        
        try? modelContext.save()
    }
    
    func addToProgress(_ additionalValue: Int, for date: Date, modelContext: ModelContext) {
        let currentValue = progressForDate(date)
        let newValue = max(0, currentValue + additionalValue)
        updateProgress(to: newValue, for: date, modelContext: modelContext)
    }
    
    func complete(for date: Date, modelContext: ModelContext) {
        updateProgress(to: goal, for: date, modelContext: modelContext)
    }
    
    func resetProgress(for date: Date, modelContext: ModelContext) {
        updateProgress(to: 0, for: date, modelContext: modelContext)
    }
}
