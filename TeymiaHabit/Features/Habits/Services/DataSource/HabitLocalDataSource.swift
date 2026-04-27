import Foundation
import SwiftData

@MainActor
final class HabitLocalDataSource: HabitDataSourceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Habit CRUD
    
    func fetchHabits() throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func insert(_ habit: Habit) {
        modelContext.insert(habit)
    }
    
    func delete(_ habit: Habit) {
        modelContext.delete(habit)
    }
    
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("HabitLocalDataSource: Failed to save: \(error)")
        }
    }
    
    // MARK: - Completion CRUD
    
    func fetchCompletions(for habit: Habit, on date: Date) -> [HabitCompletion] {
        let calendar = Calendar.current
        return habit.completions?.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        } ?? []
    }
    
    func insert(_ completion: HabitCompletion) {
        modelContext.insert(completion)
    }
    
    func delete(_ completion: HabitCompletion) {
        modelContext.delete(completion)
    }
}

extension HabitLocalDataSource {
    @MainActor
    static var preview: HabitLocalDataSource {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(
                for: Habit.self, HabitCompletion.self,
                configurations: config
            )
            return HabitLocalDataSource(modelContext: container.mainContext)
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }
}
