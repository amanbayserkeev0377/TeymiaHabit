import Foundation
import SwiftData

/// Service for managing habit progress for any date (today or past)
@MainActor
final class ProgressService {
    static let shared = ProgressService()
    
    private init() {}
    
    // MARK: - Progress Management
    
    /// Get current progress for any date
    func getProgress(for habit: Habit, date: Date) -> Int {
        if Calendar.current.isDateInToday(date) {
            // For today - use TimerService
            let habitId = habit.uuid.uuidString
            return TimerService.shared.getCurrentProgress(for: habitId)
        } else {
            // For other dates - use database
            return habit.progressForDate(date)
        }
    }
    
    /// Set progress for any date
    func setProgress(_ progress: Int, for habit: Habit, date: Date, modelContext: ModelContext) throws {
        if Calendar.current.isDateInToday(date) {
            // For today - use TimerService
            let habitId = habit.uuid.uuidString
            TimerService.shared.setProgress(progress, for: habitId)
        }
        
        // Always save to database for persistence
        try saveProgressToDatabase(progress, for: habit, date: date, modelContext: modelContext)
    }
    
    /// Add progress for any date (can be negative for decrement)
    func addProgress(_ value: Int, for habit: Habit, date: Date, modelContext: ModelContext) throws {
        let currentProgress = getProgress(for: habit, date: date)
        let newProgress: Int
        
        switch habit.type {
        case .count:
            newProgress = max(0, min(currentProgress + value, 999999))
        case .time:
            newProgress = max(0, min(currentProgress + value, 86400)) // 24 hours max
        }
        
        try setProgress(newProgress, for: habit, date: date, modelContext: modelContext)
    }
    
    /// Reset progress for any date
    func resetProgress(for habit: Habit, date: Date, modelContext: ModelContext) throws {
        try setProgress(0, for: habit, date: date, modelContext: modelContext)
    }
    
    /// Complete habit for any date
    func completeHabit(_ habit: Habit, date: Date, modelContext: ModelContext) throws {
        try setProgress(habit.goal, for: habit, date: date, modelContext: modelContext)
    }
    
    // MARK: - Timer Management (Today only)
    
    /// Check if timer is running for today
    func isTimerRunning(for habit: Habit) -> Bool {
        guard habit.type == .time else { return false }
        let habitId = habit.uuid.uuidString
        return TimerService.shared.isTimerRunning(for: habitId)
    }
    
    /// Toggle timer for today
    func toggleTimer(for habit: Habit, date: Date, modelContext: ModelContext) throws -> Bool {
        guard habit.type == .time && Calendar.current.isDateInToday(date) else {
            return false
        }
        
        let habitId = habit.uuid.uuidString
        let timerService = TimerService.shared
        
        if timerService.isTimerRunning(for: habitId) {
            // Stop timer
            timerService.stopTimer(for: habitId)
            try saveProgressToDatabase(timerService.getCurrentProgress(for: habitId),
                                     for: habit, date: date, modelContext: modelContext)
            return false
        } else {
            // Start timer
            let dbProgress = habit.progressForDate(date)
            return timerService.startTimer(for: habitId, initialProgress: dbProgress)
        }
    }
    
    // MARK: - Database Operations
    
    private func saveProgressToDatabase(_ progress: Int, for habit: Habit, date: Date, modelContext: ModelContext) throws {
        // Remove existing completions for this date
        if let existingCompletions = habit.completions?.filter({
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }) {
            for completion in existingCompletions {
                modelContext.delete(completion)
            }
        }
        
        // Add new completion if there's progress
        if progress > 0 {
            let completion = HabitCompletion(
                date: date,
                value: progress,
                habit: habit
            )
            modelContext.insert(completion)
        }
        
        try modelContext.save()
        print("💾 Progress saved: \(progress) for \(date)")
    }
    
    // MARK: - Computed Properties
    
    func completionPercentage(for habit: Habit, date: Date) -> Double {
        let progress = getProgress(for: habit, date: date)
        return habit.goal > 0 ? Double(progress) / Double(habit.goal) : 0
    }
    
    func isCompleted(habit: Habit, date: Date) -> Bool {
        return getProgress(for: habit, date: date) >= habit.goal
    }
    
    func formattedProgress(for habit: Habit, date: Date) -> String {
        let progress = getProgress(for: habit, date: date)
        
        switch habit.type {
        case .count:
            return progress.formattedAsProgress(total: habit.goal)
        case .time:
            return progress.formattedAsTime()
        }
    }
}
