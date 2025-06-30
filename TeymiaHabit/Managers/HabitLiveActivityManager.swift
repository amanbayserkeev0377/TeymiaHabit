import ActivityKit
import Foundation
import SwiftData
import SwiftUI

// MARK: - Activity Manager for Main App
@Observable @MainActor
final class HabitLiveActivityManager {
    private var currentActivity: Activity<HabitActivityAttributes>?
    
    // App Groups identifier - используем напрямую для избежания ошибок
    private var appGroupsID: String {
        // Определяем bundle ID для выбора правильного App Groups
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return "group.com.amanbayserkeev.teymiahabit"
        }
        
        if bundleId.contains(".dev") {
            return "group.com.amanbayserkeev.teymiahabit.dev"
        } else {
            return "group.com.amanbayserkeev.teymiahabit"
        }
    }
    
    // MARK: - Public Interface
    
    func startActivity(
        for habit: Habit,
        currentProgress: Int,
        timerStartTime: Date
    ) async {
        // Only support time-based habits
        guard habit.type == .time else {
            print("⚠️ Live Activities only supported for time-based habits")
            return
        }
        
        // End any existing activity
        await endCurrentActivity()
        
        // Check if Live Activities are enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities disabled by user")
            return
        }
        
        let attributes = HabitActivityAttributes(
            habitId: habit.uuid.uuidString,
            habitName: habit.title, // используем title вместо name
            habitGoal: habit.goal,
            habitType: habit.type == .time ? .time : .count
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
            
            currentActivity = activity
            print("✅ Live Activity started: \(activity.id)")
            
        } catch {
            handleActivityError(error)
        }
    }
    
    func updateActivity(
        currentProgress: Int,
        isTimerRunning: Bool,
        timerStartTime: Date?
    ) async {
        guard let activity = currentActivity else { return }
        
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
    
    func endCurrentActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalContent = ActivityContent(
            state: activity.content.state,
            staleDate: Date()
        )
        
        await activity.end(finalContent, dismissalPolicy: .immediate)
        currentActivity = nil
        
        print("✅ Live Activity ended")
    }
    
    var hasActiveActivity: Bool {
        currentActivity?.activityState == .active
    }
    
    // MARK: - App Launch Restoration
    
    func restoreActiveActivityIfNeeded() async {
        let activities = Activity<HabitActivityAttributes>.activities
        if let activity = activities.first {
            currentActivity = activity
            print("✅ Restored existing Live Activity: \(activity.id)")
        }
    }
    
    // MARK: - Listen for Widget Actions
    
    func startListeningForWidgetActions() {
        // Poll for changes from widget intents
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkForWidgetActions()
            }
        }
    }
    
    private func checkForWidgetActions() async {
        guard let userDefaults = UserDefaults(suiteName: appGroupsID),
              let actionData = userDefaults.dictionary(forKey: "live_activity_action"),
              let action = actionData["action"] as? String,
              let habitId = actionData["habitId"] as? String,
              let timestamp = actionData["timestamp"] as? TimeInterval else {
            return
        }
        
        // Check if this is a new action (prevent duplicate processing)
        let lastProcessedKey = "last_processed_timestamp"
        let lastProcessed = UserDefaults.standard.double(forKey: lastProcessedKey)
        
        guard timestamp > lastProcessed else { return }
        
        // Mark as processed
        UserDefaults.standard.set(timestamp, forKey: lastProcessedKey)
        
        // Clear the action
        userDefaults.removeObject(forKey: "live_activity_action")
        
        // Notify the app about the action
        let notification = WidgetActionNotification(
            action: WidgetAction(rawValue: action) ?? .toggleTimer,
            habitId: habitId,
            timestamp: Date(timeIntervalSince1970: timestamp)
        )
        
        NotificationCenter.default.post(
            name: .widgetActionReceived,
            object: notification
        )
    }
    
    // MARK: - Error Handling
    
    private func handleActivityError(_ error: Error) {
        print("❌ Failed to start Live Activity: \(error)")
        // Note: ActivityKit.ActivityError is only available in newer iOS versions
        // For now, just log the general error
    }
}
