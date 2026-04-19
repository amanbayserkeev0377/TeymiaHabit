import SwiftData
import SwiftUI

#if os(iOS)
import ActivityKit

@Observable @MainActor
final class HabitLiveActivityManager {
    private var activeActivities: [String: Activity<HabitActivityAttributes>] = [:]
    
    init() {}
    
    // MARK: - Public Interface
    
    func startActivity(for habit: Habit, currentProgress: Int, timerStartTime: Date) async {
        guard habit.type == .time else { return }
        let habitId = habit.uuid.uuidString
        
        if activeActivities[habitId] != nil {
            await updateActivity(for: habitId, currentProgress: currentProgress, isTimerRunning: true, timerStartTime: timerStartTime)
            return
        }
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = HabitActivityAttributes(
            habitId: habitId,
            habitName: habit.title,
            habitGoal: habit.goal,
            habitType: habit.type == .time ? .time : .count,
            habitIcon: habit.iconName,
            habitIconColor: habit.iconColor,
            habitHexColor: habit.hexColor
        )
        
        let initialState = HabitActivityAttributes.ContentState(
            currentProgress: currentProgress,
            isTimerRunning: true,
            timerStartTime: timerStartTime,
            lastUpdateTime: Date()
        )
        
        let activityContent = ActivityContent(state: initialState, staleDate: Date().addingTimeInterval(30))
        
        do {
            let activity = try Activity.request(attributes: attributes, content: activityContent, pushType: nil)
            activeActivities[habitId] = activity
        } catch {
            print("Live Activity error: \(error)")
        }
    }
    
    func updateActivity(for habitId: String, currentProgress: Int, isTimerRunning: Bool, timerStartTime: Date?) async {
        guard let activity = activeActivities[habitId] else { return }
        
        let updatedState = HabitActivityAttributes.ContentState(
            currentProgress: currentProgress,
            isTimerRunning: isTimerRunning,
            timerStartTime: timerStartTime,
            lastUpdateTime: Date()
        )
        
        await activity.update(ActivityContent(state: updatedState, staleDate: Date().addingTimeInterval(30)))
    }
    
    func endActivity(for habitId: String) async {
        guard let activity = activeActivities[habitId] else { return }
        await activity.end(ActivityContent(state: activity.content.state, staleDate: Date()), dismissalPolicy: .immediate)
        activeActivities.removeValue(forKey: habitId)
    }
    
    func endAllActivities() async {
        for (_, activity) in activeActivities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        activeActivities.removeAll()
    }
    
    func hasActiveActivity(for habitId: String) -> Bool {
        activeActivities[habitId]?.activityState == .active
    }
    
    var totalActiveActivities: Int { activeActivities.count }
    
    func getActiveHabitIds() -> [String] { Array(activeActivities.keys) }
    
    func getActivityState(for habitId: String) -> HabitActivityAttributes.ContentState? {
        activeActivities[habitId]?.content.state
    }
    
    func restoreActiveActivitiesIfNeeded() async {
        activeActivities.removeAll()
        for activity in Activity<HabitActivityAttributes>.activities {
            activeActivities[activity.attributes.habitId] = activity
        }
    }
}

#else
@Observable @MainActor
final class HabitLiveActivityManager {
    init() {}
    func startActivity(for habit: Habit, currentProgress: Int, timerStartTime: Date) async {}
    func updateActivity(for habitId: String, currentProgress: Int, isTimerRunning: Bool, timerStartTime: Date?) async {}
    func endActivity(for habitId: String) async {}
    func endAllActivities() async {}
    func hasActiveActivity(for habitId: String) -> Bool { false }
    var totalActiveActivities: Int { 0 }
    func getActiveHabitIds() -> [String] { [] }
    func getActivityState(for habitId: String) -> Any? { nil }
    func restoreActiveActivitiesIfNeeded() async {}
}
#endif
