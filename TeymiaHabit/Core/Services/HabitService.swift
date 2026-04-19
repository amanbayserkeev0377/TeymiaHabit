import Foundation
import SwiftData

// MARK: - Protocol
@MainActor
protocol HabitServiceProtocol {
    // Progress
    @discardableResult
    func completeHabit(for habit: Habit, date: Date, context: ModelContext) -> Bool
    @discardableResult
    func addProgress(_ delta: Int, to habit: Habit, date: Date, context: ModelContext) -> Bool
    @discardableResult
    func updateProgress(to newValue: Int, for habit: Habit, date: Date, context: ModelContext) -> Bool
    func saveProgress(_ value: Int, for habit: Habit, date: Date, context: ModelContext)
    func resetProgress(for habit: Habit, date: Date, context: ModelContext)
    
    // Skip
    func skipDate(_ date: Date, for habit: Habit, context: ModelContext)
    func unskipDate(_ date: Date, for habit: Habit, context: ModelContext)
    
    // Lifecycle
    func archive(_ habit: Habit, context: ModelContext)
    func unarchive(_ habit: Habit, context: ModelContext)
    func delete(_ habit: Habit, context: ModelContext)
}

@Observable @MainActor
final class HabitService: HabitServiceProtocol {
    private let widgetService: WidgetService
    
    init(widgetService: WidgetService) {
        self.widgetService = widgetService
    }
    
    // MARK: - Progress Management
    
    /// Complete
    @discardableResult
    func completeHabit(for habit: Habit, date: Date, context: ModelContext) -> Bool {
        let isCurrentlyCompleted = habit.progressForDate(date) >= habit.goal
        
        if habit.isSkipped(on: date) {
            unskipDate(date, for: habit, context: context)
        }
        
        if isCurrentlyCompleted {
            updateProgress(to: 0, for: habit, date: date, context: context)
            return false
        } else {
            updateProgress(to: habit.goal, for: habit, date: date, context: context)
            return true
        }
    }
    
    /// Reset
    func resetProgress(for habit: Habit, date: Date, context: ModelContext) {
        updateProgress(to: 0, for: habit, date: date, context: context)
    }
    
    /// Update
    @discardableResult
    func updateProgress(to newValue: Int, for habit: Habit, date: Date, context: ModelContext) -> Bool {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let wasCompleted = habit.progressForDate(targetDate) >= habit.goal
        let existingCompletions = habit.completions?.filter {
            calendar.isDate($0.date, inSameDayAs: targetDate)
        } ?? []
        
        for completion in existingCompletions {
            context.delete(completion)
        }
        
        if newValue > 0 {
            let newCompletion = HabitCompletion(date: targetDate, value: newValue, habit: habit)
            context.insert(newCompletion)
        }
        
        saveAndRefresh(context: context)
        
        let isCompletedNow = newValue >= habit.goal
        
        return !wasCompleted && isCompletedNow
    }
    
    /// Add
    @discardableResult
    func addProgress(_ delta: Int, to habit: Habit, date: Date, context: ModelContext) -> Bool {
        let before = habit.progressForDate(date)
        let after = max(0, before + delta)
        updateProgress(to: after, for: habit, date: date, context: context)
        
        return before < habit.goal && after >= habit.goal
    }
    
    func saveProgress(_ value: Int, for habit: Habit, date: Date, context: ModelContext) {
        let calendar = Calendar.current
        if let existing = habit.completions?.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) {
            if value > 0 {
                existing.value = value
            } else {
                context.delete(existing)
            }
        } else if value > 0 {
            let completion = HabitCompletion(date: date, value: value, habit: habit)
            context.insert(completion)
        }
    }
    
    // MARK: - Skip Managemenent
    
    func skipDate(_ date: Date, for habit: Habit, context: ModelContext) {
        let targetDate = Calendar.current.startOfDay(for: date)
        var currentSkips = habit.skippedDates
        
        if !currentSkips.contains(where: { Calendar.current.isDate($0, inSameDayAs: targetDate) }) {
            currentSkips.append(targetDate)
            habit.skippedDates = currentSkips
            saveAndRefresh(context: context)
        }
    }
    
    func unskipDate(_ date: Date, for habit: Habit, context: ModelContext) {
        let targetDate = Calendar.current.startOfDay(for: date)
        var currentSkips = habit.skippedDates
        
        currentSkips.removeAll { Calendar.current.isDate($0, inSameDayAs: targetDate) }
        habit.skippedDates = currentSkips
        saveAndRefresh(context: context)
    }

    // MARK: - Lifecycle Management
    
    func archive(_ habit: Habit, context: ModelContext) {
        habit.isArchived = true
        saveAndRefresh(context: context)
    }
    
    func unarchive(_ habit: Habit, context: ModelContext) {
        habit.isArchived = false
        saveAndRefresh(context: context)
    }
    
    func delete(_ habit: Habit, context: ModelContext) {
        context.delete(habit)
        saveAndRefresh(context: context)
    }
    
    // MARK: - Private Helpers
    
    private func saveAndRefresh(context: ModelContext) {
        do {
            try context.save()
            widgetService.reloadWidgetsAfterDataChange()
        } catch {
            print("HabitService: Failed to save context: \(error)")
        }
    }
}
