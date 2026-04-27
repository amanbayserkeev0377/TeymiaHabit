@testable import TeymiaHabit
import Foundation

@MainActor
final class MockHabitDataSource: HabitDataSourceProtocol {
    // In-memory storage
    var habits: [Habit] = []
    var completions: [HabitCompletion] = []
    
    // Call counters for verifying behavior in tests
    var saveCallCount = 0
    var insertHabitCallCount = 0
    var deleteHabitCallCount = 0
    var insertCompletionCallCount = 0
    var deleteCompletionCallCount = 0
    
    func fetchHabits() throws -> [Habit] {
        habits
    }
    
    func insert(_ habit: Habit) {
        insertHabitCallCount += 1
        habits.append(habit)
    }
    
    func delete(_ habit: Habit) {
        deleteHabitCallCount += 1
        habits.removeAll { $0.uuid == habit.uuid }
    }
    
    func save() {
        saveCallCount += 1
    }
    
    func fetchCompletions(for habit: Habit, on date: Date) -> [HabitCompletion] {
        let calendar = Calendar.current
        return completions.filter {
            $0.habit?.uuid == habit.uuid &&
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func insert(_ completion: HabitCompletion) {
        insertCompletionCallCount += 1
        completions.append(completion)
    }
    
    func delete(_ completion: HabitCompletion) {
        deleteCompletionCallCount += 1
        completions.removeAll { $0 === completion }
    }
}
