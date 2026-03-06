import SwiftData

@MainActor
final class HabitService {
    static let shared = HabitService()
    private init() {}
    
    func delete(_ habit: Habit, context: ModelContext) {
        guard habit.modelContext != nil else { return }
        let habitId = habit.uuid.uuidString
        
        stopExternalServices(for: habitId, context: context)
        NotificationManager.shared.cancelNotifications(for: habit)
        
        context.delete(habit)
        save(context)
        HapticManager.shared.play(.error)
    }
    
    // MARK: - Archive
    func archive(_ habit: Habit, context: ModelContext) {
        guard habit.modelContext != nil else { return }
        
        habit.isArchived = true
        stopExternalServices(for: habit.uuid.uuidString, context: context)
        
        save(context)
        HapticManager.shared.play(.warning)
    }
    
    // MARK: - Unarchive
    func unarchive(_ habit: Habit, context: ModelContext) {
        habit.isArchived = false
        save(context)
        HapticManager.shared.play(.success)
    }
    
    // MARK: - Private Helpers
    private func stopExternalServices(for habitId: String, context: ModelContext) {
        TimerService.shared.stopTimer(for: habitId)
        
        Task {
            await HabitLiveActivityManager.shared.endActivity(for: habitId)
        }
        
        WidgetUpdateService.shared.reloadWidgets()
    }
    
    private func save(_ context: ModelContext) {
        try? context.save()
    }
}
