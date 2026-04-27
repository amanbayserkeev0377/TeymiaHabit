import Foundation
import SwiftData

@MainActor
protocol HabitDataSourceProtocol {
    // MARK: - Habit CRUD
    func fetchHabits() throws -> [Habit]
    func insert(_ habit: Habit)
    func delete(_ habit: Habit)
    func save()
    
    // MARK: - Completion CRUD
    func fetchCompletions(for habit: Habit, on date: Date) -> [HabitCompletion]
    func insert(_ completion: HabitCompletion)
    func delete(_ completion: HabitCompletion)
}
