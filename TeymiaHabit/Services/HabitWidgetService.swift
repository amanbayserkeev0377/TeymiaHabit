import Foundation
import SwiftData
import SwiftUI

/// Service for handling progress updates from Live Activities to main app database
@Observable @MainActor
final class HabitWidgetService {
    static let shared = HabitWidgetService()
    
    private let appGroupsID = "group.com.amanbayserkeev.teymiahabit"
    
    private init() {}
    
    func saveProgressToDatabase(habitId: String, progress: Int) async {
        guard let habitUUID = UUID(uuidString: habitId),
              let mainContext = AppModelContext.shared.modelContext else {
            return
        }
        
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.uuid == habitUUID
            }
        )
        
        guard let habits = try? mainContext.fetch(descriptor),
              let habit = habits.first else {
            return
        }
        
        let today = Date()
        habit.updateProgress(to: progress, for: today, modelContext: mainContext)
        
        try? mainContext.save()
        
        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidSave,
            object: mainContext
        )
        
        WidgetUpdateService.shared.reloadWidgetsAfterDataChange()
    }
}
