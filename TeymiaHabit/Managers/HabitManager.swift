import SwiftUI
import SwiftData

enum HabitManagerError: LocalizedError {
    case invalidHabit
    
    var errorDescription: String? {
        "Invalid habit UUID"
    }
}

/// Manages lifecycle of HabitDetailViewModels to prevent memory leaks and ensure proper cleanup
/// Reuses ViewModels for the same habit to maintain state during navigation
@MainActor
final class HabitManager: ObservableObject {
    static let shared = HabitManager()
    
    private var viewModels: [String: HabitDetailViewModel] = [:]
    
    private init() {}
    
    /// Gets or creates a ViewModel for a habit, reusing existing ones when possible
    func getViewModel(for habit: Habit, date: Date, modelContext: ModelContext) throws -> HabitDetailViewModel {
        let habitId = habit.uuid.uuidString
        
        guard !habitId.isEmpty else {
            throw HabitManagerError.invalidHabit
        }
        
        if let existingViewModel = viewModels[habitId] {
            existingViewModel.updateDisplayedDate(date)
            return existingViewModel
        }
        
        let viewModel = HabitDetailViewModel(habit: habit, initialDate: date, modelContext: modelContext)
        viewModels[habitId] = viewModel
        
        return viewModel
    }
    
    /// Removes and cleans up a specific ViewModel
    func removeViewModel(for habitId: String) {
        if let viewModel = viewModels[habitId] {
            viewModel.syncWithTimerService()
            viewModel.cleanup()
            viewModels.removeValue(forKey: habitId)
        }
    }
    
    /// Cleans up ViewModels that don't have active timers or Live Activities
    func cleanupInactiveViewModels() {
        let timerService = TimerService.shared
        let liveActivityManager = HabitLiveActivityManager.shared
        
        for (habitId, viewModel) in viewModels {
            let hasActiveTimer = timerService.isTimerRunning(for: habitId)
            let hasActiveLiveActivity = liveActivityManager.hasActiveActivity(for: habitId)
            
            if !hasActiveTimer && !hasActiveLiveActivity {
                viewModel.syncWithTimerService()
                viewModel.cleanup()
                viewModels.removeValue(forKey: habitId)
            }
        }
    }
    
    /// Cleans up all ViewModels (called on app termination)
    func cleanupAllViewModels() {
        for (_, viewModel) in viewModels {
            viewModel.syncWithTimerService()
            viewModel.cleanup()
        }
        viewModels.removeAll()
    }
}
