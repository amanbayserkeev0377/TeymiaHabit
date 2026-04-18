import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit: Identifiable {
    // MARK: - Core Properties
    var uuid: UUID = UUID()
    var title: String = ""
    var iconName: String = "book"
    var iconColor: HabitIconColor = HabitIconColor.primary
    var hexColor: String? = nil
    var type: HabitType = HabitType.count
    var goal: Int = 1
    var activeDaysBitmask: Int = 0b1111111
    var displayOrder: Int = 0
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var startDate: Date = Date()
    
    @Attribute(.externalStorage) private var skippedDatesData: Data?
    @Attribute(.externalStorage) private var reminderTimesData: Data?
    
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]?
    
    @Transient
    var actualColor: Color {
        if let hex = hexColor {
            return Color(hex: hex)
        }
        return iconColor.baseColor
    }
    
    // MARK: - Computed Data
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
                    activeDaysBitmask |= (1 << weekday.rawValue)
                }
            }
        }
    }
    
    var skippedDates: [Date] {
        get {
            guard let data = skippedDatesData else { return [] }
            return (try? JSONDecoder().decode([Date].self, from: data)) ?? []
        }
        set { skippedDatesData = try? JSONEncoder().encode(newValue) }
    }
    
    var reminderTimes: [Date]? {
        get {
            guard let data = reminderTimesData else { return nil }
            return try? JSONDecoder().decode([Date].self, from: data)
        }
        set { reminderTimesData = (newValue != nil && !newValue!.isEmpty) ? try? JSONEncoder().encode(newValue) : nil }
    }
    
    // MARK: - Initializer
    init(
        title: String = "",
        type: HabitType = .count,
        goal: Int = 1,
        iconName: String,
        iconColor: HabitIconColor = .primary,
        hexColor: String? = nil,
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
        self.hexColor = hexColor
        self.createdAt = createdAt
        self.startDate = Calendar.current.startOfDay(for: startDate)
        
        if let days = activeDays {
            self.activeDays = days
        } else {
            self.activeDaysBitmask = 0b1111111
        }
        self.reminderTimes = reminderTimes
    }
    
    // MARK: - Update Method
    func update(
        title: String,
        type: HabitType,
        goal: Int,
        iconName: String,
        iconColor: HabitIconColor,
        hexColor: String?,
        activeDays: [Bool],
        reminderTimes: [Date]?,
        startDate: Date
    ) {
        self.title = title
        self.type = type
        self.goal = goal
        self.iconName = iconName
        self.iconColor = iconColor
        self.hexColor = hexColor
        self.activeDays = activeDays
        self.reminderTimes = reminderTimes
        self.startDate = Calendar.current.startOfDay(for: startDate)
    }
}

// MARK: - Logic & Calculations (ReadOnly)
extension Habit {
    
    func isActive(on weekday: Weekday) -> Bool {
        (activeDaysBitmask & (1 << weekday.rawValue)) != 0
    }
    
    func isActiveOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        if calendar.startOfDay(for: date) < calendar.startOfDay(for: startDate) { return false }
        return isActive(on: Weekday.from(date: date))
    }
    
    func progressForDate(_ date: Date) -> Int {
        guard let completions = completions else { return 0 }
        let calendar = Calendar.current
        return completions
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.value }
    }
    
    func isSkipped(on date: Date) -> Bool {
        let calendar = Calendar.current
        let dateStart = calendar.startOfDay(for: date)
        return skippedDates.contains { calendar.isDate($0, inSameDayAs: dateStart) }
    }
    
    func completionPercentageForDate(_ date: Date) -> Double {
        guard goal > 0 else { return progressForDate(date) > 0 ? 1.0 : 0.0 }
        let percentage = Double(progressForDate(date)) / Double(goal)
        return min(percentage, 2.0)
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
    
    var formattedGoal: String {
        type == .count ? "\(goal)" : goal.formattedAsLocalizedDuration()
    }
    
    func isExceededForDate(_ date: Date) -> Bool {
            progressForDate(date) > goal
        }
}
