#if !targetEnvironment(macCatalyst)
import ActivityKit
#endif

import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class HabitLiveActivityManager {
    static let shared = HabitLiveActivityManager()
    
    #if !targetEnvironment(macCatalyst)
    private var activeActivities: [String: Activity<HabitActivityAttributes>] = [:]
    #endif
    
    private init() {}
    
    // MARK: - Public Interface
    
    func startActivity(
        for habit: Habit,
        currentProgress: Int,
        timerStartTime: Date
    ) async {
        #if !targetEnvironment(macCatalyst)
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
            habitIcon: habit.iconName,
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
        #endif
    }
    
    func updateActivity(
        for habitId: String,
        currentProgress: Int,
        isTimerRunning: Bool,
        timerStartTime: Date?
    ) async {
        #if !targetEnvironment(macCatalyst)
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
        #endif
    }
    
    func endActivity(for habitId: String) async {
        #if !targetEnvironment(macCatalyst)
        guard let activity = activeActivities[habitId] else { return }
        
        let finalContent = ActivityContent(
            state: activity.content.state,
            staleDate: Date()
        )
        
        await activity.end(finalContent, dismissalPolicy: .immediate)
        activeActivities.removeValue(forKey: habitId)
        #endif
    }
    
    func endAllActivities() async {
        #if !targetEnvironment(macCatalyst)
        for (_, activity) in activeActivities {
            let finalContent = ActivityContent(
                state: activity.content.state,
                staleDate: Date()
            )
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
        activeActivities.removeAll()
        #endif
    }
    
    func hasActiveActivity(for habitId: String) -> Bool {
        #if !targetEnvironment(macCatalyst)
        return activeActivities[habitId]?.activityState == .active
        #else
        return false
        #endif
    }
    
    var totalActiveActivities: Int {
        #if !targetEnvironment(macCatalyst)
        return activeActivities.count
        #else
        return 0
        #endif
    }
    
    // MARK: - Activity State Access
    
    func getActiveHabitIds() -> [String] {
        #if !targetEnvironment(macCatalyst)
        return Array(activeActivities.keys)
        #else
        return []
        #endif
    }
    
    func getActivityState(for habitId: String) -> HabitActivityAttributes.ContentState? {
        #if !targetEnvironment(macCatalyst)
        return activeActivities[habitId]?.content.state
        #else
        return nil
        #endif
    }
    
    // MARK: - App Launch Restoration
    
    func restoreActiveActivitiesIfNeeded() async {
        #if !targetEnvironment(macCatalyst)
        let activities = Activity<HabitActivityAttributes>.activities
        
        // Clear current state
        activeActivities.removeAll()
        
        // Restore all active activities
        for activity in activities {
            let habitId = activity.attributes.habitId
            activeActivities[habitId] = activity
        }
        #endif
    }
}
