import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class HabitWidgetService {
    static let shared = HabitWidgetService()
    
    private let timerService = TimerService.shared
    private let liveActivityManager = HabitLiveActivityManager.shared
    private let appGroupsID = "group.com.amanbayserkeev.teymiahabit"
    
    private var widgetActionTimer: Timer?
    private var isListening = false
    
    private init() {}
    
    // MARK: - Public Properties
    
    var isCurrentlyListening: Bool {
        return isListening
    }
    
    // MARK: - Public Interface
    
    func startListening() {
        guard !isListening else {
            print("🔧 HabitWidgetService already listening")
            return
        }
        
        widgetActionTimer?.invalidate()
        
        widgetActionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkForWidgetActions()
            }
        }
        
        isListening = true
        print("🔧 HabitWidgetService started listening")
    }
    
    func stopListening() {
        widgetActionTimer?.invalidate()
        widgetActionTimer = nil
        isListening = false
        print("🔧 HabitWidgetService stopped listening")
    }
    
    // MARK: - Widget Action Processing
    
    private func checkForWidgetActions() async {
        guard let userDefaults = UserDefaults(suiteName: appGroupsID) else {
            print("❌ Cannot access UserDefaults for app group")
            return
        }
        
        // Получаем все активные Live Activities
        let activeHabits = liveActivityManager.getActiveHabitIds()
        
        for habitId in activeHabits {
            let uniqueKey = "live_activity_action_\(habitId)"
            
            guard let actionData = userDefaults.dictionary(forKey: uniqueKey) else {
                continue
            }
            
            guard let action = actionData["action"] as? String,
                  let actionHabitId = actionData["habitId"] as? String,
                  let timestamp = actionData["timestamp"] as? TimeInterval else {
                print("❌ Invalid action data format for habit \(habitId)")
                userDefaults.removeObject(forKey: uniqueKey)
                continue
            }
            
            guard actionHabitId == habitId else {
                print("⚠️ HabitId mismatch: expected \(habitId), got \(actionHabitId)")
                userDefaults.removeObject(forKey: uniqueKey)
                continue
            }
            
            // Check if this is a new action
            let lastProcessedKey = "last_processed_timestamp_\(habitId)"
            let lastProcessed = UserDefaults.standard.double(forKey: lastProcessedKey)
            
            guard timestamp > lastProcessed else {
                continue
            }
            
            print("🔍 Processing widget action: \(action) for habit: \(habitId)")
            
            // Mark as processed and clear action
            UserDefaults.standard.set(timestamp, forKey: lastProcessedKey)
            userDefaults.removeObject(forKey: uniqueKey)
            
            // Process the action
            await handleAction(
                WidgetAction(rawValue: action) ?? .toggleTimer,
                habitId: habitId
            )
        }
    }
    
    // MARK: - Action Handling
    
    private func handleAction(_ action: WidgetAction, habitId: String) async {
        switch action {
        case .toggleTimer:
            await toggleTimer(habitId: habitId)
        case .dismissActivity:
            await liveActivityManager.endActivity(for: habitId)
        }
    }
    
    private func toggleTimer(habitId: String) async {
        // Get current state from Live Activity
        guard let activityState = liveActivityManager.getActivityState(for: habitId) else {
            print("❌ No Live Activity found for habit: \(habitId)")
            return
        }
        
        if activityState.isTimerRunning {
            // Stop timer
            await stopTimer(habitId: habitId, currentProgress: activityState.currentProgress)
        } else {
            // Start timer
            await startTimer(habitId: habitId, baseProgress: activityState.currentProgress)
        }
    }
    
    private func stopTimer(habitId: String, currentProgress: Int) async {
        print("🛑 Stopping timer for habitId: \(habitId)")
        
        if let finalProgress = timerService.stopTimer(for: habitId) {
            // Save to database
            await saveProgressToDatabase(habitId: habitId, progress: finalProgress)
            
            // Update Live Activity
            await liveActivityManager.updateActivity(
                for: habitId,
                currentProgress: finalProgress,
                isTimerRunning: false,
                timerStartTime: nil
            )
            
            print("✅ Timer stopped, final progress: \(finalProgress)")
        }
    }
    
    private func startTimer(habitId: String, baseProgress: Int) async {
        print("🚀 Starting timer for habitId: \(habitId)")
        
        let success = timerService.startTimer(for: habitId, baseProgress: baseProgress)
        
        if success {
            let startTime = timerService.getTimerStartTime(for: habitId)
            
            // Update Live Activity
            await liveActivityManager.updateActivity(
                for: habitId,
                currentProgress: baseProgress,
                isTimerRunning: true,
                timerStartTime: startTime
            )
            
            print("✅ Timer started for habitId: \(habitId)")
        } else {
            print("❌ Failed to start timer for habitId: \(habitId)")
        }
    }
    
    // MARK: - Database Operations
    
    private func saveProgressToDatabase(habitId: String, progress: Int) async {
        // ✅ ИСПРАВЛЕНО: Используем общий ModelContext из приложения
        guard let appDelegate = await getAppMainContext() else {
            print("❌ Cannot access main app ModelContext")
            return
        }
        
        do {
            guard let habitUUID = UUID(uuidString: habitId) else {
                print("❌ Invalid habitId format: \(habitId)")
                return
            }
            
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { habit in
                    habit.uuid == habitUUID
                }
            )
            
            let habits = try appDelegate.fetch(descriptor)
            guard let habit = habits.first else {
                print("❌ Habit not found for habitId: \(habitId)")
                return
            }
            
            let today = Date()
            habit.updateProgress(to: progress, for: today, modelContext: appDelegate)
            
            try appDelegate.save()
            print("✅ Progress saved to database: \(habitId) -> \(progress)")
            
        } catch {
            print("❌ Failed to save progress: \(error)")
        }
    }
    
    // ✅ НОВОЕ: Получаем основной ModelContext приложения
    private func getAppMainContext() async -> ModelContext? {
        return AppModelContext.shared.modelContext
    }
}
