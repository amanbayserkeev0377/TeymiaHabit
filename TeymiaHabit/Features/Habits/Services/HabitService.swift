import Foundation
import SwiftData

// MARK: - Protocol
@MainActor
protocol HabitServiceProtocol {
    // Progress
    @discardableResult
    func completeHabit(for habit: Habit, date: Date) -> Bool
    @discardableResult
    func addProgress(_ delta: Int, to habit: Habit, date: Date) -> Bool
    @discardableResult
    func updateProgress(to newValue: Int, for habit: Habit, date: Date) -> Bool
    func saveProgress(_ value: Int, for habit: Habit, date: Date)
    func resetProgress(for habit: Habit, date: Date)
    
    // Skip
    func skipDate(_ date: Date, for habit: Habit)
    func unskipDate(_ date: Date, for habit: Habit)
    
    // Lifecycle
    func archive(_ habit: Habit)
    func unarchive(_ habit: Habit)
    func delete(_ habit: Habit)
}

// MARK: - Implementation
@Observable @MainActor
final class HabitService: HabitServiceProtocol {
    private let dataSource: any HabitDataSourceProtocol
    private let widgetService: any WidgetServiceProtocol
    
    init(dataSource: any HabitDataSourceProtocol, widgetService: any WidgetServiceProtocol) {
        self.dataSource = dataSource
        self.widgetService = widgetService
    }
    
    // MARK: - Progress Management
    
    @discardableResult
    func completeHabit(for habit: Habit, date: Date) -> Bool {
        let isCurrentlyCompleted = habit.progressForDate(date) >= habit.goal
        
        if habit.isSkipped(on: date) {
            unskipDate(date, for: habit)
        }
        
        if isCurrentlyCompleted {
            updateProgress(to: 0, for: habit, date: date)
            return false
        } else {
            updateProgress(to: habit.goal, for: habit, date: date)
            return true
        }
    }
    
    func resetProgress(for habit: Habit, date: Date) {
        updateProgress(to: 0, for: habit, date: date)
    }
    
    @discardableResult
    func updateProgress(to newValue: Int, for habit: Habit, date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let wasCompleted = habit.progressForDate(targetDate) >= habit.goal
        
        // Delete existing completions for this date
        let existingCompletions = dataSource.fetchCompletions(for: habit, on: targetDate)
        existingCompletions.forEach { dataSource.delete($0) }
        
        if newValue > 0 {
            let newCompletion = HabitCompletion(date: targetDate, value: newValue, habit: habit)
            dataSource.insert(newCompletion)
        }
        
        saveAndRefresh()
        
        let isCompletedNow = newValue >= habit.goal
        return !wasCompleted && isCompletedNow
    }
    
    @discardableResult
    func addProgress(_ delta: Int, to habit: Habit, date: Date) -> Bool {
        let before = habit.progressForDate(date)
        let after = max(0, before + delta)
        updateProgress(to: after, for: habit, date: date)
        return before < habit.goal && after >= habit.goal
    }
    
    func saveProgress(_ value: Int, for habit: Habit, date: Date) {
        let existingCompletions = dataSource.fetchCompletions(for: habit, on: date)
        
        if let existing = existingCompletions.first {
            if value > 0 {
                existing.value = value
            } else {
                dataSource.delete(existing)
            }
        } else if value > 0 {
            let completion = HabitCompletion(date: date, value: value, habit: habit)
            dataSource.insert(completion)
        }
        
        saveAndRefresh()
    }
    
    // MARK: - Skip Management
    
    func skipDate(_ date: Date, for habit: Habit) {
        let targetDate = Calendar.current.startOfDay(for: date)
        var currentSkips = habit.skippedDates
        
        guard !currentSkips.contains(where: {
            Calendar.current.isDate($0, inSameDayAs: targetDate)
        }) else { return }
        
        currentSkips.append(targetDate)
        habit.skippedDates = currentSkips
        saveAndRefresh()
    }
    
    func unskipDate(_ date: Date, for habit: Habit) {
        let targetDate = Calendar.current.startOfDay(for: date)
        var currentSkips = habit.skippedDates
        
        currentSkips.removeAll {
            Calendar.current.isDate($0, inSameDayAs: targetDate)
        }
        habit.skippedDates = currentSkips
        saveAndRefresh()
    }
    
    // MARK: - Lifecycle Management
    
    func archive(_ habit: Habit) {
        habit.isArchived = true
        saveAndRefresh()
    }
    
    func unarchive(_ habit: Habit) {
        habit.isArchived = false
        saveAndRefresh()
    }
    
    func delete(_ habit: Habit) {
        dataSource.delete(habit)
        saveAndRefresh()
    }
    
    // MARK: - Private Helpers
    
    private func saveAndRefresh() {
        dataSource.save()
        widgetService.reloadWidgetsAfterDataChange()
    }
}
