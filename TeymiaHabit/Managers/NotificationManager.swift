import Foundation
import UserNotifications
import SwiftUI
import SwiftData

@Observable @MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    
    var permissionStatus: Bool = false
    
    var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    private(set) var selectedNotificationSound: NotificationSound {
        didSet {
            UserDefaults.standard.set(selectedNotificationSound.rawValue, forKey: "selectedNotificationSound")
        }
    }
    
    private init() {
        let soundRaw = UserDefaults.standard.string(forKey: "selectedNotificationSound") ?? NotificationSound.system.rawValue
        self.selectedNotificationSound = NotificationSound(rawValue: soundRaw) ?? .system
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        Task { await refreshPermissionStatus() }
    }
    
    // MARK: - Habit Goal Completed Notification

    func sendGoalAchievedNotification(for habit: Habit) async {
        guard notificationsEnabled, await ensureAuthorization() else { return }
        
        let content = UNMutableNotificationContent()
        
        content.title = String(localized: "goal_achieved_title")
        content.body = String(localized: "goal_achieved_body \(habit.title)")
        content.sound = selectedNotificationSound.notificationSound
        
        let request = UNNotificationRequest(
            identifier: "goal-achieved-\(habit.uuid.uuidString)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Authorization
    
    func ensureAuthorization() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        if settings.authorizationStatus == .authorized {
            permissionStatus = true
            return true
        }
        
        if settings.authorizationStatus == .notDetermined {
            let options: UNAuthorizationOptions = [.alert, .sound]
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: options)) ?? false
            
            permissionStatus = granted
            return granted
        }
        
        return settings.authorizationStatus == .authorized
    }
    
    func checkNotificationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleNotifications(for habit: Habit) async -> Bool {
        guard notificationsEnabled, await ensureAuthorization() else {
            cancelNotifications(for: habit)
            return false
        }
        
        guard let reminderTimes = habit.reminderTimes, !reminderTimes.isEmpty else {
            cancelNotifications(for: habit)
            return false
        }
        
        cancelNotifications(for: habit)
        
        for (timeIndex, reminderTime) in reminderTimes.enumerated() {
            let calendar = Calendar.userPreferred
            let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
            
            for (dayIndex, isActive) in habit.activeDays.enumerated() where isActive {
                let weekday = calendar.systemWeekdayFromOrdered(index: dayIndex)
                
                var dateComponents = DateComponents()
                dateComponents.hour = components.hour
                dateComponents.minute = components.minute
                dateComponents.weekday = weekday
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                let content = UNMutableNotificationContent()
                content.title = habit.title
                content.body = ""
                content.sound = selectedNotificationSound.notificationSound
                
                let request = UNNotificationRequest(
                    identifier: "\(habit.uuid.uuidString)-\(weekday)-\(timeIndex)",
                    content: content,
                    trigger: trigger
                )
                
                try? await UNUserNotificationCenter.current().add(request)
            }
        }
        
        return true
    }
    
    func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = (settings.authorizationStatus == .authorized)
        
        if !permissionStatus && notificationsEnabled {
            notificationsEnabled = false
        }
    }
    
    func cancelNotifications(for habit: Habit) {
        let habitID = habit.uuid.uuidString
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(habitID) }
                .map { $0.identifier }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
                
                print("Successfully cancelled \(identifiersToRemove.count) notifications for habit: \(habitID)")
            }
        }
    }
    
    func updateAllNotifications(modelContext: ModelContext) async {
        guard notificationsEnabled else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            return
        }
        
        let isAuthorized = await ensureAuthorization()
        
        if !isAuthorized {
            await MainActor.run {
                notificationsEnabled = false
            }
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            return
        }
        
        let descriptor = FetchDescriptor<Habit>()
        let allHabits = (try? modelContext.fetch(descriptor)) ?? []
        
        let habitsWithReminders = allHabits.filter { habit in
            guard let reminderTimes = habit.reminderTimes else { return false }
            return !reminderTimes.isEmpty
        }
        
        for habit in habitsWithReminders {
            _ = await scheduleNotifications(for: habit)
        }
    }
    
    func setSelectedNotificationSound(_ sound: NotificationSound, modelContext: ModelContext) async {
        selectedNotificationSound = sound
        
        if notificationsEnabled {
            await updateAllNotifications(modelContext: modelContext)
        }
    }
}
