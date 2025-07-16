import Foundation
import UserNotifications
import SwiftUI
import SwiftData

@Observable @MainActor
class NotificationManager {
    static let shared = NotificationManager()
    
    var permissionStatus: Bool = false
    
    private var _notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(_notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    var notificationsEnabled: Bool {
        get { _notificationsEnabled }
        set { _notificationsEnabled = newValue }
    }
    
    
    private init() {
        self._notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        
        Task {
            permissionStatus = await checkNotificationStatus()
        }
    }
    
    // Единый метод для обеспечения разрешений
    func ensureAuthorization() async -> Bool {
        
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        print("🔔 Current authorization status: \(settings.authorizationStatus.rawValue)")
        
        if settings.authorizationStatus == .authorized {
            permissionStatus = true
            print("🔔 Already authorized")
            return true
        }
        
        if settings.authorizationStatus == .notDetermined {
            print("🔔 Requesting authorization...")
            do {
                let options: UNAuthorizationOptions = [.alert, .sound, .badge]
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
                
                permissionStatus = granted
                print("🔔 Authorization granted: \(granted)")
                return granted
            } catch {
                print("🔔 Authorization error: \(error)")
                permissionStatus = false
                return false
            }
        }
        
        print("🔔 Authorization denied or other status: \(settings.authorizationStatus)")
        return settings.authorizationStatus == .authorized
    }
    
    func scheduleNotifications(for habit: Habit) async -> Bool {
        // Проверяем, есть ли у нас разрешение на уведомления
        guard notificationsEnabled, await ensureAuthorization() else {
            cancelNotifications(for: habit)
            return false
        }
        
        // Проверяем наличие времен напоминаний
        guard let reminderTimes = habit.reminderTimes, !reminderTimes.isEmpty else {
            cancelNotifications(for: habit)
            return false
        }
        
        // Сначала отменяем старые уведомления
        cancelNotifications(for: habit)
        
        // Для каждого времени напоминания создаем уведомления по дням
        for (timeIndex, reminderTime) in reminderTimes.enumerated() {
            let calendar = Calendar.userPreferred
            let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
            
            // Создаем уведомления для каждого активного дня недели
            for (dayIndex, isActive) in habit.activeDays.enumerated() where isActive {
                let weekday = calendar.systemWeekdayFromOrdered(index: dayIndex)
                
                var dateComponents = DateComponents()
                dateComponents.hour = components.hour
                dateComponents.minute = components.minute
                dateComponents.weekday = weekday
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                let content = UNMutableNotificationContent()
                content.title = "notifications_habit_time".localized
                content.body = "notifications_dont_forget".localized(with: habit.title)
                content.sound = .default
                
                let request = UNNotificationRequest(
                    identifier: "\(habit.uuid.uuidString)-\(weekday)-\(timeIndex)",
                    content: content,
                    trigger: trigger
                )
                
                do {
                    try await UNUserNotificationCenter.current().add(request)
                } catch {
                    print("Ошибка при планировании уведомления: \(error.localizedDescription)")
                    // Продолжаем добавлять другие уведомления, если возможно
                }
            }
        }
        
        return true
    }
    
    func cancelNotifications(for habit: Habit) {
        // Получаем все возможные идентификаторы
        let identifiers: [String] = (0..<5).flatMap { timeIndex in
            (1...7).map { weekday in
                "\(habit.uuid.uuidString)-\(weekday)-\(timeIndex)"
            }
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
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
        
        do {
            let allHabits = try modelContext.fetch(descriptor)
            
            let habitsWithReminders = allHabits.filter { habit in
                habit.reminderTimes != nil && !(habit.reminderTimes?.isEmpty ?? true)
            }
            
            for habit in habitsWithReminders {
                _ = await scheduleNotifications(for: habit)
            }
            
            print("✅ Updated notifications for \(habitsWithReminders.count) habits")
        } catch {
            print("❌ Error updating notifications: \(error)")
        }
    }
    
    func checkNotificationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}
