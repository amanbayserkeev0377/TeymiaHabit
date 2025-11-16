import ActivityKit
import Foundation
import SwiftData
import SwiftUI

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
        guard habit.type == .time else {
            return
        }
        
        let habitId = habit.uuid.uuidString
        
        if activeActivities[habitId] != nil {
            await updateActivity(
                for: habitId,
                currentProgress: currentProgress,
                isTimerRunning: true,
                timerStartTime: timerStartTime
            )
            return
        }
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }
        
        let attributes = HabitActivityAttributes(
            habitId: habitId,
            habitName: habit.title,
            habitGoal: habit.goal,
            habitType: habit.type == .time ? .time : .count,
            habitIcon: habit.iconName ?? "check",
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
            
        } catch {
            // Silently handle Live Activity creation failures
            // Common causes: user disabled Live Activities, too many active activities
        }
    }
    
    func updateActivity(
        for habitId: String,
        currentProgress: Int,
        isTimerRunning: Bool,
        timerStartTime: Date?
    ) async {
        guard let activity = activeActivities[habitId] else {
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
    }
    
    func endAllActivities() async {
        for (_, activity) in activeActivities {
            let finalContent = ActivityContent(
                state: activity.content.state,
                staleDate: Date()
            )
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
        activeActivities.removeAll()
    }
    
    func hasActiveActivity(for habitId: String) -> Bool {
        activeActivities[habitId]?.activityState == .active
    }
    
    var totalActiveActivities: Int {
        activeActivities.count
    }
    
    // MARK: - Activity State Access
    
    func getActiveHabitIds() -> [String] {
        Array(activeActivities.keys)
    }
    
    func getActivityState(for habitId: String) -> HabitActivityAttributes.ContentState? {
        activeActivities[habitId]?.content.state
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
        }
    }
}
