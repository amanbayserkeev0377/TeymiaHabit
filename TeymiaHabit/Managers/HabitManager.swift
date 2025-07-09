import SwiftUI
import SwiftData

enum HabitManagerError: LocalizedError {
    case invalidHabit
    
    var errorDescription: String? {
        return "Invalid habit UUID"
    }
}

@MainActor
final class HabitManager: ObservableObject {
    static let shared = HabitManager()
    
    private var viewModels: [String: HabitDetailViewModel] = [:]
    
    private init() {}
    
    func getViewModel(for habit: Habit, date: Date, modelContext: ModelContext) throws -> HabitDetailViewModel {
        let habitId = habit.uuid.uuidString
        
        guard !habitId.isEmpty else {
            throw HabitManagerError.invalidHabit
        }
        
        if let existingViewModel = viewModels[habitId] {
            print("🔄 Reusing ViewModel for \(habit.title)")
            existingViewModel.updateDisplayedDate(date)
            return existingViewModel
        }
        
        print("🔧 Creating NEW ViewModel for \(habit.title)")
        let viewModel = HabitDetailViewModel(habit: habit, initialDate: date, modelContext: modelContext)
        viewModels[habitId] = viewModel
        
        print("📊 Total ViewModels: \(viewModels.count)")
        return viewModel
    }
    
    func removeViewModel(for habitId: String) {
        if let viewModel = viewModels[habitId] {
            print("🗑️ Removing ViewModel for habitId: \(habitId)")
            viewModel.syncWithTimerService()
            viewModel.cleanup()
            viewModels.removeValue(forKey: habitId)
        }
    }
    
    func cleanupInactiveViewModels() {
        let timerService = TimerService.shared
        let liveActivityManager = HabitLiveActivityManager.shared
        
        for (habitId, viewModel) in viewModels {
            let hasActiveTimer = timerService.isTimerRunning(for: habitId)
            let hasActiveLiveActivity = liveActivityManager.hasActiveActivity(for: habitId)
            
            if !hasActiveTimer && !hasActiveLiveActivity {
                print("🧹 Cleaning up inactive ViewModel for habitId: \(habitId)")
                viewModel.syncWithTimerService()
                viewModel.cleanup()
                viewModels.removeValue(forKey: habitId)
            }
        }
        
        print("📊 Active ViewModels: \(viewModels.count)")
    }
    
    func cleanupAllViewModels() {
        print("🧹 Cleaning up all ViewModels: \(viewModels.count)")
        
        for (_, viewModel) in viewModels {
            viewModel.syncWithTimerService()
            viewModel.cleanup()
        }
        viewModels.removeAll()
    }
}
