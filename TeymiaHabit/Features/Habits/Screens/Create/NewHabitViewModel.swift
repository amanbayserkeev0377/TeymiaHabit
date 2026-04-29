import SwiftData
import SwiftUI

@Observable @MainActor
final class NewHabitViewModel {
    private let modelContext: ModelContext
    private let notificationManager: NotificationManager
    private let widgetService: WidgetService
    
    let habit: Habit?
    
    var title = ""
    var selectedType: HabitType = .count
    var countGoal: Int = 1
    var hours: Int = 1
    var minutes: Int = 0
    var activeDays: [Bool] = Array(repeating: true, count: 7)
    var isReminderEnabled = false
    var reminderTimes: [Date] = [Date()]
    var startDate = Date()
    var selectedIcon: String = "book.fill"
    var selectedIconColor: HabitIconColor = .primary
    var selectedHexColor: String? = nil
    var onSaveCompletion: (() -> Void)?
    
    var actualColor: Color {
        if let hex = selectedHexColor { return Color(hex: hex) }
        return selectedIconColor.baseColor
    }
    
    init(
        modelContext: ModelContext,
        notificationManager: NotificationManager,
        widgetService: WidgetService,
        habit: Habit? = nil
    ) {
        self.modelContext = modelContext
        self.notificationManager = notificationManager
        self.widgetService = widgetService
        self.habit = habit
        
        if let habit = habit { setupInitialValues(from: habit) }
    }
    
    private func setupInitialValues(from habit: Habit) {
        title = habit.title
        selectedType = habit.type
        countGoal = habit.type == .count ? habit.goal : 1
        hours = habit.type == .time ? habit.goal / 3600 : 1
        minutes = habit.type == .time ? (habit.goal % 3600) / 60 : 0
        activeDays = habit.activeDays
        isReminderEnabled = habit.reminderTimes != nil && !habit.reminderTimes!.isEmpty
        reminderTimes = habit.reminderTimes ?? [Date()]
        startDate = habit.startDate
        selectedIcon = habit.iconName
        selectedIconColor = habit.iconColor
        selectedHexColor = habit.hexColor
    }
    
    var isFormValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasValidTitle = !trimmedTitle.isEmpty
        
        let hasValidGoal = selectedType == .count
        ? countGoal > 0
        : (hours > 0 || minutes > 0)
        
        return hasValidTitle && hasValidGoal
    }
    
    private var effectiveGoal: Int {
        switch selectedType {
        case .count:
            return countGoal
        case .time:
            let totalSeconds = (hours * 3600) + (minutes * 60)
            return min(totalSeconds, 86400)
        }
    }
    
    func save() {
        if selectedType == .count && countGoal > 999999 { countGoal = 999999 }
        if selectedType == .time {
            let totalSeconds = (hours * 3600) + (minutes * 60)
            if totalSeconds > 86400 {
                hours = 24
                minutes = 0
            }
        }
        
        if let existingHabit = habit {
            existingHabit.update(
                title: title,
                type: selectedType,
                goal: effectiveGoal,
                iconName: selectedIcon,
                iconColor: selectedIconColor,
                hexColor: selectedHexColor,
                activeDays: activeDays,
                reminderTimes: isReminderEnabled ? reminderTimes : nil,
                startDate: Calendar.current.startOfDay(for: startDate)
            )
            handleNotifications(for: existingHabit)
        } else {
            let newHabit = Habit(
                title: title,
                type: selectedType,
                goal: effectiveGoal,
                iconName: selectedIcon,
                iconColor: selectedIconColor,
                hexColor: selectedHexColor,
                createdAt: Date(),
                activeDays: activeDays,
                reminderTimes: isReminderEnabled ? reminderTimes : nil,
                startDate: startDate
            )
            modelContext.insert(newHabit)
            try? modelContext.save()
            handleNotifications(for: newHabit)
        }
        
        widgetService.reloadWidgetsAfterDataChange()
    }
    
    private func handleNotifications(for habit: Habit) {
        if isReminderEnabled {
            Task {
                let isAuthorized = await notificationManager.ensureAuthorization()
                
                if isAuthorized {
                    _ = await notificationManager.scheduleNotifications(for: habit)
                } else {
                    isReminderEnabled = false
                }
            }
        } else {
            notificationManager.cancelNotifications(for: habit)
        }
    }
}
