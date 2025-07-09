import ActivityKit
import Foundation
import SwiftData
import SwiftUI

// MARK: - Activity Manager for Main App
@Observable @MainActor
final class HabitLiveActivityManager {
    static let shared = HabitLiveActivityManager()
    
    private var activeActivities: [String: Activity<HabitActivityAttributes>] = [:]
    
    private init() {}
    
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
    
    // MARK: - New Methods for HabitWidgetService
    
    func getActiveHabitIds() -> [String] {
        return Array(activeActivities.keys)
    }
    
    func getActivityState(for habitId: String) -> HabitActivityAttributes.ContentState? {
        return activeActivities[habitId]?.content.state
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
