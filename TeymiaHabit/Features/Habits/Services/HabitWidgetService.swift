import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class HabitWidgetService {
    private let modelContext: ModelContext
    private let habitService: any HabitServiceProtocol
    private let appGroupsID = "group.com.amanbayserkeev.teymiahabit"
    
    init(modelContext: ModelContext, habitService: any HabitServiceProtocol) {
        self.modelContext = modelContext
        self.habitService = habitService
    }
    
    func saveProgressToDatabase(habitId: String, progress: Int) async {
        guard let habitUUID = UUID(uuidString: habitId) else { return }
        
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { $0.uuid == habitUUID }
        )
        
        guard let habit = try? modelContext.fetch(descriptor).first else { return }
        
        habitService.updateProgress(
            to: progress,
            for: habit,
            date: Date()
        )
    }
}
