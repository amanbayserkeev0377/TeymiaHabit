import SwiftUI
import SwiftData

struct NewHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    private let habit: Habit?
    private let onSaveCompletion: (() -> Void)?
    
    @State private var title = ""
    @State private var selectedType: HabitType = .count
    @State private var countGoal: Int = 1
    @State private var hours: Int = 1
    @State private var minutes: Int = 0
    @State private var activeDays: [Bool] = Array(repeating: true, count: 7)
    @State private var isReminderEnabled = false
    @State private var reminderTimes: [Date] = [Date()]
    @State private var startDate = Date()
    @State private var selectedIcon: String = "book"
    @State private var selectedIconColor: HabitIconColor = .primary
    @State private var showPaywall = false
    
    // MARK: - Initialization
    
    init(habit: Habit? = nil, onSaveCompletion: (() -> Void)? = nil) {
        self.habit = habit
        self.onSaveCompletion = onSaveCompletion
        
        if let habit = habit {
            _title = State(initialValue: habit.title)
            _selectedType = State(initialValue: habit.type)
            _countGoal = State(initialValue: habit.type == .count ? habit.goal : 1)
            _hours = State(initialValue: habit.type == .time ? habit.goal / 3600 : 1)
            _minutes = State(initialValue: habit.type == .time ? (habit.goal % 3600) / 60 : 0)
            _activeDays = State(initialValue: habit.activeDays)
            _isReminderEnabled = State(initialValue: habit.reminderTimes != nil && !habit.reminderTimes!.isEmpty)
            _reminderTimes = State(initialValue: habit.reminderTimes ?? [Date()])
            _startDate = State(initialValue: habit.startDate)
            _selectedIcon = State(initialValue: habit.iconName)
            _selectedIconColor = State(initialValue: habit.iconColor)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
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
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label {
                        TextField("habit_name", text: $title)
                            .fontWeight(.medium)
                            .submitLabel(.done)
                    } icon: { RowIcon(systemName: "pencil") }
                    
                    NavigationLink {
                        IconPickerView(selectedIcon: $selectedIcon, selectedColor: $selectedIconColor)
                    } label: {
                        HStack {
                            Label { Text("icon") }
                            icon: { RowIcon(systemName: "questionmark") }
                            
                            Spacer()
                            
                            Image(selectedIcon)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(
                                    LinearGradient(colors: [selectedIconColor.lightColor, selectedIconColor.darkColor], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                    }
                }
                
                Section {
                    GoalSection(
                        selectedType: $selectedType,
                        countGoal: $countGoal,
                        hours: $hours,
                        minutes: $minutes
                    )
                }
                
                Section {
                    RepeatDaysView(activeDays: $activeDays)
                    StartDateSection(startDate: $startDate)
                    ReminderSection(
                        isReminderEnabled: $isReminderEnabled,
                        reminderTimes: $reminderTimes,
                        onShowPaywall: {
                            showPaywall = true
                        }
                    )
                }
            }
            .navigationTitle(habit == nil ? "create_habit" : "edit_habit")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.immediately)
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .toolbar {
                CloseToolbarButton()
                
                ConfirmationToolbarButton(
                    action: {
                        guard isFormValid else { return }
                        saveHabit()
                    },
                    isDisabled: !isFormValid
                )
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveHabit() {
        if selectedType == .count && countGoal > 999999 {
            countGoal = 999999
        }
        
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
                createdAt: Date(),
                activeDays: activeDays,
                reminderTimes: isReminderEnabled ? reminderTimes : nil,
                startDate: startDate
            )
            
            modelContext.insert(newHabit)
            handleNotifications(for: newHabit)
        }
        
        WidgetUpdateService.shared.reloadWidgetsAfterDataChange()
        
        if let onSaveCompletion = onSaveCompletion {
            onSaveCompletion()
        } else {
            dismiss()
        }
    }
    
    private func handleNotifications(for habit: Habit) {
        if isReminderEnabled {
            Task {
                let isAuthorized = await NotificationManager.shared.ensureAuthorization()
                
                if isAuthorized {
                    let success = await NotificationManager.shared.scheduleNotifications(for: habit)
                    if !success {
                        // Silent fail for non-critical operation
                    }
                } else {
                    isReminderEnabled = false
                }
            }
        } else {
            NotificationManager.shared.cancelNotifications(for: habit)
        }
    }
}
