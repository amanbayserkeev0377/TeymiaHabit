import ActivityKit
import Foundation
import SwiftData
import SwiftUI

// MARK: - Activity Manager for Main App
@Observable @MainActor
final class HabitLiveActivityManager {
    static let shared = HabitLiveActivityManager()
    
    // Changed: Support multiple activities instead of single
    private var activeActivities: [String: Activity<HabitActivityAttributes>] = [:]
    private var widgetActionTimer: Timer? // ← Один таймер для всех
    private var isListening = false
    
    private init() {}
    
    // App Groups identifier
    private let appGroupsID = "group.com.amanbayserkeev.teymiahabit"
    
    // MARK: - Public Interface
    
    func startActivity(
        for habit: Habit,
        currentProgress: Int,
        timerStartTime: Date
    ) async {
        print("🔍 startActivity called for: \(habit.title)")
        
        guard habit.type == .time else {
            print("⚠️ Live Activities only supported for time-based habits")
            return
        }
        
        let habitId = habit.uuid.uuidString
        print("🔍 habitId: \(habitId)")
        print("🔍 Current active activities count: \(activeActivities.count)")
        print("🔍 Current active activities: \(activeActivities.keys)")
        
        if activeActivities[habitId] != nil {
            print("⚠️ Live Activity already exists for \(habit.title), updating instead")
            await updateActivity(
                for: habitId,
                currentProgress: currentProgress,
                isTimerRunning: true,
                timerStartTime: timerStartTime
            )
            return
        }
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities disabled by user")
            return
        }
        
        print("🔍 Creating new Live Activity for \(habit.title)")
        
        let attributes = HabitActivityAttributes(
            habitId: habitId,
            habitName: habit.title,
            habitGoal: habit.goal,
            habitType: habit.type == .time ? .time : .count,
            habitIcon: habit.iconName ?? "checkmark",
            habitIconColor: habit.iconColor
        )
        
        let initialState = HabitActivityAttributes.ContentState(
            currentProgress: currentProgress,
            isTimerRunning: true,
            timerStartTime: timerStartTime,
            lastUpdateTime: Date()
        )
        
        let activityContent = ActivityContent(
            state: initialState,
            staleDate: Date().addingTimeInterval(30)
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            
            activeActivities[habitId] = activity
            print("✅ Live Activity created and stored for \(habit.title)")
            print("🔍 New total active activities: \(activeActivities.count)")
            print("🔍 All active habit IDs: \(activeActivities.keys)")
            
        } catch {
            print("❌ Failed to create Live Activity: \(error)")
            handleActivityError(error)
        }
    }
    
    func updateActivity(
        for habitId: String,
        currentProgress: Int,
        isTimerRunning: Bool,
        timerStartTime: Date?
    ) async {
        guard let activity = activeActivities[habitId] else {
            print("⚠️ No active activity found for habit: \(habitId)")
            return
        }
        
        let updatedState = HabitActivityAttributes.ContentState(
            currentProgress: currentProgress,
            isTimerRunning: isTimerRunning,
            timerStartTime: timerStartTime,
            lastUpdateTime: Date()
        )
        
        let activityContent = ActivityContent(
            state: updatedState,
            staleDate: Date().addingTimeInterval(30)
        )
        
        await activity.update(activityContent)
    }
    
    func endActivity(for habitId: String) async {
        guard let activity = activeActivities[habitId] else { return }
        
        let finalContent = ActivityContent(
            state: activity.content.state,
            staleDate: Date()
        )
        
        await activity.end(finalContent, dismissalPolicy: .immediate)
        activeActivities.removeValue(forKey: habitId)
        print("✅ Live Activity ended for \(habitId) - Remaining: \(activeActivities.count)")
    }
    
    func endAllActivities() async {
        for (habitId, activity) in activeActivities {
            let finalContent = ActivityContent(
                state: activity.content.state,
                staleDate: Date()
            )
            await activity.end(finalContent, dismissalPolicy: .immediate)
            print("✅ Ended Live Activity for: \(habitId)")
        }
        activeActivities.removeAll()
        print("✅ All Live Activities ended")
    }
    
    func hasActiveActivity(for habitId: String) -> Bool {
        return activeActivities[habitId]?.activityState == .active
    }
    
    var totalActiveActivities: Int {
        return activeActivities.count
    }
    
    // MARK: - App Launch Restoration
    
    func restoreActiveActivitiesIfNeeded() async {
        let activities = Activity<HabitActivityAttributes>.activities
        
        // Clear current state
        activeActivities.removeAll()
        
        // Restore all active activities
        for activity in activities {
            let habitId = activity.attributes.habitId
            activeActivities[habitId] = activity
            print("✅ Restored Live Activity: \(activity.attributes.habitName)")
        }
        
        print("✅ Restored \(activeActivities.count) Live Activities")
    }
    
    // MARK: - Listen for Widget Actions
    
    func startListeningForWidgetActions() {
        // Предотвращаем множественные listener'ы
        guard !isListening else {
            print("🔧 Widget action listener already running")
            return
        }
        
        // Останавливаем существующий таймер если есть
        widgetActionTimer?.invalidate()
        
        // Создаем ОДИН таймер для всех Live Activities
        widgetActionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkForWidgetActions()
            }
        }
        
        isListening = true
        print("🔧 Widget action listener started (singleton)")
    }
    
    func stopListeningForWidgetActions() {
        widgetActionTimer?.invalidate()
        widgetActionTimer = nil
        isListening = false
        print("🔧 Widget action listener stopped")
    }
    
    var isListeningForWidgetActions: Bool {
        return isListening
    }
    
    // ИСПРАВЛЕНИЕ: просто убираем deinit - timer будет остановлен при stopListeningForWidgetActions()
    // deinit убран, так как требует экспериментальные флаги
    // Вместо этого полагаемся на явный вызов stopListeningForWidgetActions()
    
    private func checkForWidgetActions() async {
        guard let userDefaults = UserDefaults(suiteName: appGroupsID) else {
            print("❌ Cannot access UserDefaults for app group: \(appGroupsID)")
            return
        }
        
        guard let actionData = userDefaults.dictionary(forKey: "live_activity_action") else {
            // Нет действий - это нормально, не логируем каждую секунду
            return
        }
        
        print("🔍 Found widget action data: \(actionData)")
        
        guard let action = actionData["action"] as? String,
              let habitId = actionData["habitId"] as? String,
              let timestamp = actionData["timestamp"] as? TimeInterval else {
            print("❌ Invalid action data format")
            userDefaults.removeObject(forKey: "live_activity_action") // Очищаем битые данные
            return
        }
        
        print("🔍 Parsed action: \(action), habitId: \(habitId)")
        
        // Check if this is a new action (prevent duplicate processing)
        let lastProcessedKey = "last_processed_timestamp"
        let lastProcessed = UserDefaults.standard.double(forKey: lastProcessedKey)
        
        guard timestamp > lastProcessed else {
            print("🔍 Action already processed (timestamp: \(timestamp) <= \(lastProcessed))")
            return
        }
        
        print("🔍 Processing new widget action: \(action) for habit: \(habitId)")
        
        // Mark as processed FIRST
        UserDefaults.standard.set(timestamp, forKey: lastProcessedKey)
        
        // Clear the action FIRST
        userDefaults.removeObject(forKey: "live_activity_action")
        print("🔍 Cleared action data from UserDefaults")
        
        // Handle dismissActivity action locally before notifying
        if action == "dismissActivity" {
            print("🔍 Handling dismissActivity locally for: \(habitId)")
            await endActivity(for: habitId)
            return
        }
        
        // Notify the app about other actions
        let notification = WidgetActionNotification(
            action: WidgetAction(rawValue: action) ?? .toggleTimer,
            habitId: habitId,
            timestamp: Date(timeIntervalSince1970: timestamp)
        )
        
        print("🔍 Posting notification for action: \(action) to habit: \(habitId)")
        NotificationCenter.default.post(
            name: .widgetActionReceived,
            object: notification
        )
        print("🔍 Notification posted successfully")
    }
    
    // MARK: - Error Handling
    
    private func handleActivityError(_ error: Error) {
        print("❌ Failed to start Live Activity: \(error)")
        print("❌ Error details: \(error.localizedDescription)")
        
        // Log error without using ActivityError enum (not available in all iOS versions)
        if error.localizedDescription.contains("disabled") {
            print("❌ Activities are disabled by user")
        } else if error.localizedDescription.contains("limit") {
            print("❌ Too many activities running")
        }
    }
}
