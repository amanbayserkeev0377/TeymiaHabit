import Foundation
import SwiftData

/// Core habit model that represents a user's habit with progress tracking
/// Supports both count-based habits (e.g., "drink 8 glasses") and time-based habits (e.g., "read 30 minutes")
@Model
final class Habit {
    
    // MARK: - Identity
    
    var uuid: UUID = UUID()
    
    // MARK: - Basic Properties
    
    var title: String = ""
    var type: HabitType = HabitType.count
    var goal: Int = 1
    var iconName: String? = "check"
    var iconColor: HabitIconColor = HabitIconColor.primary
    
    // MARK: - Status
    
    var isArchived: Bool = false
    
    // MARK: - Timestamps
    
    var createdAt: Date = Date()
    var startDate: Date = Date()
    var displayOrder: Int = 0
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]?
    
    // MARK: - Active Days Configuration
    
    /// Bitmask representing which days of the week this habit is active
    /// Uses bit flags: Sunday=1, Monday=2, Tuesday=4, etc.
    /// Example: 0b1111100 = weekdays only, 0b1111111 = every day
    var activeDaysBitmask: Int = 0b1111111
    
    // MARK: - Reminder Configuration
    
    /// Serialized reminder times (stored as JSON data for CloudKit compatibility)
    @Attribute(.externalStorage)
    private var reminderTimesData: Data?
    
    /// Computed property for accessing reminder times as Date array
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
    
    /// Computed property for UI compatibility - converts bitmask to bool array
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
    
    // MARK: - Initializers
    
    init(
        title: String = "",
        type: HabitType = .count,
        goal: Int = 1,
        iconName: String? = "check",
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
        
        // Setup active days bitmask
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
    
    // MARK: - Utility Methods
    
    static func createDefaultActiveDaysBitMask() -> Int {
        return 0b1111111 // All days active
    }
    
    var id: String {
        uuid.uuidString
    }
}

// MARK: - Active Days Management

extension Habit {
    
    func isActive(on weekday: Weekday) -> Bool {
        (activeDaysBitmask & (1 << weekday.rawValue)) != 0
    }
    
    func setActive(_ active: Bool, for weekday: Weekday) {
        if active {
            activeDaysBitmask |= (1 << weekday.rawValue)
        } else {
            activeDaysBitmask &= ~(1 << weekday.rawValue)
        }
    }
    
    /// Checks if habit should be tracked on a specific date
    /// Considers both the start date and active weekdays
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

// MARK: - Reminder Management

extension Habit {
    
    var hasReminders: Bool {
        reminderTimes != nil && !(reminderTimes?.isEmpty ?? true)
    }
}

// MARK: - Progress Tracking

extension Habit {
    
    func progressForDate(_ date: Date) -> Int {
        guard let completions = completions else { return 0 }
        
        let calendar = Calendar.current
        let filteredCompletions = completions.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }
        
        return filteredCompletions.reduce(0) { $0 + $1.value }
    }
    
    func formatProgress(_ progress: Int) -> String {
        switch type {
        case .count:
            return "\(progress)"
        case .time:
            return progress.formattedAsTime()
        }
    }
    
    func formattedProgress(for date: Date) -> String {
        let progress = progressForDate(date)
        return formatProgress(progress)
    }
    
    @MainActor
    func liveProgress(for date: Date) -> Int {
        // In widgets, only use database progress for performance
        progressForDate(date)
    }

    @MainActor
    func formattedLiveProgress(for date: Date) -> String {
        let progress = liveProgress(for: date)
        return formatProgress(progress)
    }
    
    func isCompletedForDate(_ date: Date) -> Bool {
        progressForDate(date) >= goal
    }
    
    func isExceededForDate(_ date: Date) -> Bool {
        progressForDate(date) > goal
    }
    
    func completionPercentageForDate(_ date: Date) -> Double {
        let progress = min(progressForDate(date), 999999) // Cap extremely high values
        
        if goal <= 0 {
            return progress > 0 ? 1.0 : 0.0
        }
        
        let percentage = Double(progress) / Double(goal)
        return min(percentage, 1.0) // Cap at 100%
    }
    
    func addProgress(_ value: Int, for date: Date = .now) {
        let completion = HabitCompletion(date: date, value: value, habit: self)
        
        if completions == nil {
            completions = []
        }
        completions?.append(completion)
    }
}

// MARK: - Goal Formatting

extension Habit {
    
    var formattedGoal: String {
        switch type {
        case .count:
            return "\(goal)"
        case .time:
            return goal.formattedAsLocalizedDuration()
        }
    }
}

// MARK: - SwiftData Operations

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
