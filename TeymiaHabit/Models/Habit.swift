import Foundation
import SwiftData

// MARK: - Main Habit Model

/// Core habit model that represents a user's habit with progress tracking
/// Supports both count-based habits (e.g., "drink 8 glasses") and time-based habits (e.g., "read 30 minutes")
/// Uses SwiftData for persistence and CloudKit sync
@Model
final class Habit {
    
    // MARK: - Identity
    
    /// Unique identifier for the habit (used for timer services, widgets, notifications)
    var uuid: UUID = UUID()
    
    // MARK: - Basic Properties
    
    /// User-defined name for the habit
    var title: String = ""
    
    /// Type of habit: count-based or time-based
    var type: HabitType = HabitType.count
    
    /// Daily goal value (count for count habits, seconds for time habits)
    var goal: Int = 1
    
    /// SF Symbol name for the habit icon
    var iconName: String? = "checkmark"
    
    /// Color theme for the habit icon and UI elements
    var iconColor: HabitIconColor = HabitIconColor.primary
    
    // MARK: - Status
    
    /// Whether the habit is archived (hidden from main interface)
    var isArchived: Bool = false
    
    // MARK: - Timestamps
    
    /// When the habit was first created
    var createdAt: Date = Date()
    
    /// First date when habit tracking should begin
    var startDate: Date = Date()
    
    /// Display order in the habits list (lower numbers appear first)
    var displayOrder: Int = 0
    
    // MARK: - Relationships
    
    /// All completion records for this habit (SwiftData relationship)
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
    /// Returns nil if no reminders are set
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
    /// Array order follows user's preferred week start (Monday-first vs Sunday-first)
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
    
    /// Creates a new habit with specified parameters
    /// - Parameters:
    ///   - title: Display name for the habit
    ///   - type: Whether it's count-based or time-based
    ///   - goal: Daily target (count or seconds)
    ///   - iconName: SF Symbol name for the icon
    ///   - iconColor: Color theme for the habit
    ///   - createdAt: Creation timestamp
    ///   - activeDays: Which days of week are active (nil = all days)
    ///   - reminderTimes: Notification times (nil = no reminders)
    ///   - startDate: When tracking should begin
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
    
    /// Updates habit properties (used when editing existing habits)
    /// - Parameters:
    ///   - title: New display name
    ///   - type: New habit type
    ///   - goal: New daily goal
    ///   - iconName: New icon name
    ///   - iconColor: New color theme
    ///   - activeDays: New active days configuration
    ///   - reminderTimes: New reminder times
    ///   - startDate: New start date
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
    
    /// Creates default bitmask with all days active
    /// - Returns: Bitmask representing all 7 days of the week
    static func createDefaultActiveDaysBitMask() -> Int {
        return 0b1111111 // All days active
    }
    
    /// Convenience property returning UUID as string (for compatibility)
    var id: String {
        return uuid.uuidString
    }
}

// MARK: - Active Days Management

extension Habit {
    
    /// Checks if habit is active on a specific weekday
    /// - Parameter weekday: The weekday to check
    /// - Returns: true if habit should be tracked on this day
    func isActive(on weekday: Weekday) -> Bool {
        return (activeDaysBitmask & (1 << weekday.rawValue)) != 0
    }
    
    /// Sets whether habit is active on a specific weekday
    /// - Parameters:
    ///   - active: Whether to activate or deactivate
    ///   - weekday: The weekday to modify
    func setActive(_ active: Bool, for weekday: Weekday) {
        if active {
            activeDaysBitmask |= (1 << weekday.rawValue)
        } else {
            activeDaysBitmask &= ~(1 << weekday.rawValue)
        }
    }
    
    /// Checks if habit should be tracked on a specific date
    /// Considers both the start date and active weekdays
    /// - Parameter date: Date to check
    /// - Returns: true if habit should be active on this date
    func isActiveOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.userPreferred
        
        // Check if date is before habit start date
        let dateStartOfDay = calendar.startOfDay(for: date)
        let startDateOfDay = calendar.startOfDay(for: startDate)
        
        if dateStartOfDay < startDateOfDay {
            return false
        }
        
        // Check if this weekday is active
        let weekday = Weekday.from(date: date)
        return isActive(on: weekday)
    }
}

// MARK: - Reminder Management

extension Habit {
    
    /// Whether this habit has any reminder notifications set
    var hasReminders: Bool {
        return reminderTimes != nil && !(reminderTimes?.isEmpty ?? true)
    }
}

// MARK: - Progress Tracking

extension Habit {
    
    /// Gets the total progress value for a specific date
    /// Sums all completion records for that day
    /// - Parameter date: Date to get progress for
    /// - Returns: Total progress value (count or seconds)
    func progressForDate(_ date: Date) -> Int {
        guard let completions = completions else { return 0 }
        
        let calendar = Calendar.current
        let filteredCompletions = completions.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }
        
        let total = filteredCompletions.reduce(0) { $0 + $1.value }
        return total
    }
    
    /// Formats a progress value according to habit type
    /// - Parameter progress: Raw progress value to format
    /// - Returns: Formatted string (e.g., "5" for count, "1:30:00" for time)
    func formatProgress(_ progress: Int) -> String {
        switch type {
        case .count:
            return "\(progress)"
        case .time:
            return progress.formattedAsTime()
        }
    }
    
    /// Gets formatted progress string for a specific date
    /// - Parameter date: Date to get progress for
    /// - Returns: Formatted progress string
    func formattedProgress(for date: Date) -> String {
        let progress = progressForDate(date)
        return formatProgress(progress)
    }
    
    /// Gets live progress including active timers (main actor required)
    /// For widgets, returns regular progress from database only
    /// - Parameter date: Date to get live progress for
    /// - Returns: Current progress including running timers
    @MainActor
    func liveProgress(for date: Date) -> Int {
        // In widgets, only use database progress for performance
        return progressForDate(date)
    }

    /// Gets formatted live progress string
    /// - Parameter date: Date to get formatted live progress for
    /// - Returns: Formatted live progress string
    @MainActor
    func formattedLiveProgress(for date: Date) -> String {
        let progress = liveProgress(for: date)
        return formatProgress(progress)
    }
    
    /// Checks if daily goal was reached on a specific date
    /// - Parameter date: Date to check completion for
    /// - Returns: true if progress >= goal
    func isCompletedForDate(_ date: Date) -> Bool {
        return progressForDate(date) >= goal
    }
    
    /// Checks if progress exceeded the daily goal
    /// - Parameter date: Date to check for over-achievement
    /// - Returns: true if progress > goal
    func isExceededForDate(_ date: Date) -> Bool {
        return progressForDate(date) > goal
    }
    
    /// Calculates completion percentage for a date (capped at 100%)
    /// - Parameter date: Date to calculate percentage for
    /// - Returns: Percentage as decimal (0.0 to 1.0)
    func completionPercentageForDate(_ date: Date) -> Double {
        let progress = min(progressForDate(date), 999999) // Cap extremely high values
        
        if goal <= 0 {
            return progress > 0 ? 1.0 : 0.0
        }
        
        let percentage = Double(progress) / Double(goal)
        return min(percentage, 1.0) // Cap at 100%
    }
    
    /// Adds progress to the habit (creates new completion record)
    /// - Parameters:
    ///   - value: Progress value to add
    ///   - date: Date to add progress for (defaults to now)
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
    
    /// Formatted goal string with proper localization for time units
    /// Uses DateComponentsFormatter for international time formatting
    /// - Returns: Localized goal string (e.g., "5" for count, "1h 30m" for time)
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
    
    /// Updates progress for a specific date (replaces existing completions)
    /// - Parameters:
    ///   - newValue: New total progress value
    ///   - date: Date to update progress for
    ///   - modelContext: SwiftData context for database operations
    func updateProgress(to newValue: Int, for date: Date, modelContext: ModelContext) {
        // Remove existing completions for this date
        if let existingCompletions = completions?.filter({
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }) {
            for completion in existingCompletions {
                modelContext.delete(completion)
            }
        }
        
        // Add new completion if value > 0
        if newValue > 0 {
            let completion = HabitCompletion(
                date: date,
                value: newValue,
                habit: self
            )
            modelContext.insert(completion)
        }
        
        // Save changes
        try? modelContext.save()
    }
    
    /// Adds to existing progress for a date
    /// - Parameters:
    ///   - additionalValue: Value to add (can be negative)
    ///   - date: Date to modify progress for
    ///   - modelContext: SwiftData context for database operations
    func addToProgress(_ additionalValue: Int, for date: Date, modelContext: ModelContext) {
        let currentValue = progressForDate(date)
        let newValue = max(0, currentValue + additionalValue)
        updateProgress(to: newValue, for: date, modelContext: modelContext)
    }
    
    /// Marks habit as completed for a date (sets progress to goal)
    /// - Parameters:
    ///   - date: Date to mark as completed
    ///   - modelContext: SwiftData context for database operations
    func complete(for date: Date, modelContext: ModelContext) {
        updateProgress(to: goal, for: date, modelContext: modelContext)
    }
    
    /// Resets progress to zero for a date
    /// - Parameters:
    ///   - date: Date to reset progress for
    ///   - modelContext: SwiftData context for database operations
    func resetProgress(for date: Date, modelContext: ModelContext) {
        updateProgress(to: 0, for: date, modelContext: modelContext)
    }
}
