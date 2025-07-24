import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class HabitWidgetService {
    static let shared = HabitWidgetService()
    
    private let appGroupsID = "group.com.amanbayserkeev.teymiahabit"
    
    private init() {}
    
    // MARK: - Database Operations
    
    /// Сохранить прогресс в базу данных (вызывается извне при необходимости)
    func saveProgressToDatabase(habitId: String, progress: Int) async {
        do {
            guard let habitUUID = UUID(uuidString: habitId) else {
                print("❌ Invalid habitId format: \(habitId)")
                return
            }
            
            guard let mainContext = AppModelContext.shared.modelContext else {
                print("❌ AppModelContext.shared.modelContext is nil!")
                return
            }
            
            print("🔍 Saving progress for \(habitId): \(progress)")
            
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { habit in
                    habit.uuid == habitUUID
                }
            )
            
            let habits = try mainContext.fetch(descriptor)
            guard let habit = habits.first else {
                print("❌ Habit not found for habitId: \(habitId)")
                return
            }
            
            let today = Date()
            habit.updateProgress(to: progress, for: today, modelContext: mainContext)
            
            try mainContext.save()
            
            // ✅ КРИТИЧНО: Уведомляем все другие контексты об изменениях
            NotificationCenter.default.post(
                name: .NSManagedObjectContextDidSave,
                object: mainContext
            )
            
            print("✅ Progress saved to database: \(habitId) -> \(progress)")
            
            // ✅ Обновляем виджеты после сохранения
            WidgetUpdateService.shared.reloadWidgetsAfterDataChange()
            
        } catch {
            print("❌ Failed to save progress: \(error)")
        }
    }
}
