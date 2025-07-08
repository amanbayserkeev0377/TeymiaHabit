import Foundation
import SwiftData

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
    
    // ✅ ИСПРАВЛЕНО: Используем Data для хранения массива дат
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
    
    // MARK: - Методы для работы с активными днями
    
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
    
    // MARK: - Методы для работы с напоминаниями
    
    // Проверка наличия напоминаний
    var hasReminders: Bool {
        return reminderTimes != nil && !(reminderTimes?.isEmpty ?? true)
    }
    
    // MARK: - Методы для работы с прогрессом
    
    func progressForDate(_ date: Date) -> Int {
        guard let completions = completions else {
            print("🔍 progressForDate for \(title): no completions, returning 0")
            return 0
        }
        
        let calendar = Calendar.current
        let filteredCompletions = completions.filter { calendar.isDate($0.date, inSameDayAs: date) }
        
        print("🔍 progressForDate for \(title):")
        print("   target date: \(date)")
        print("   total completions: \(completions.count)")
        print("   filtered completions: \(filteredCompletions.count)")
        
        for completion in filteredCompletions {
            print("     matched completion: date=\(completion.date), value=\(completion.value)")
        }
        
        let total = filteredCompletions.reduce(0) { $0 + $1.value }
        print("   calculated total: \(total)")
        
        return total
    }
    
    func formattedProgress(for date: Date) -> String {
        let progress = progressForDate(date)
        
        switch type {
        case .count:
            return progress.formattedAsProgress(total: goal)
        case .time:
            return progress.formattedAsTime()
        }
    }
    
    var formattedGoal: String {
        switch type {
        case .count:
            return "\(goal) \("times".localized)"
        case .time:
            let hours = goal / 3600
            let minutes = (goal % 3600) / 60
            
            if hours > 0 {
                if minutes > 0 {
                    return "hours_minutes_format".localized(with: hours, minutes)
                } else {
                    return "hours_format".localized(with: hours)
                }
            } else {
                return "minutes_format".localized(with: minutes)
            }
        }
    }
    
    func completeForDate(_ date: Date) {
        if let existingCompletions = completions?.filter({
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }) {
            for completion in existingCompletions {
                completions?.removeAll { $0.id == completion.id }
            }
        }
        
        let completion = HabitCompletion(date: date, value: goal, habit: self)
        addCompletion(completion)
    }

    func addCompletion(_ completion: HabitCompletion) {
        if completions == nil {
            completions = []
        }
        completions?.append(completion)
    }
    
    func isCompletedForDate(_ date: Date) -> Bool {
        return progressForDate(date) >= goal
    }
    
    func isExceededForDate(_ date: Date) -> Bool {
        return progressForDate(date) > goal
    }
    
    func formattedProgressValue(for date: Date) -> String {
        let progress = progressForDate(date)
        
        switch type {
        case .count:
            return progress.formattedAsProgressForRing()
        case .time:
            return progress.formattedAsTimeForRing()
        }
    }
    
    func completionPercentageForDate(_ date: Date) -> Double {
        let progress = min(progressForDate(date), 999999)
        
        if goal <= 0 {
            return progress > 0 ? 1.0 : 0.0
        }
        
        let percentage = Double(progress) / Double(goal)
        return min(percentage, 1.0)
    }
    
    func addProgress(_ value: Int, for date: Date = .now) {
        let completion = HabitCompletion(date: date, value: value, habit: self)
        
        if completions == nil {
            completions = []
        }
        completions?.append(completion)
    }
    
    // MARK: - Инициализаторы
    
    static func createDefaultActiveDaysBitMask() -> Int {
        return 0b1111111
    }
    
    var id: String {
        return uuid.uuidString
    }
    
    // ✅ ПРОСТОЙ инициализатор - только то что нужно
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
    
    // ✅ ПРОСТОЙ метод обновления
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
}

// MARK: - Live Progress Support + Native Methods
extension Habit {
    func formattedProgress(for date: Date, currentProgress: Int) -> String {
        switch type {
        case .count:
            return currentProgress.formattedAsProgress(total: goal)
        case .time:
            return currentProgress.formattedAsTime()
        }
    }
    
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
