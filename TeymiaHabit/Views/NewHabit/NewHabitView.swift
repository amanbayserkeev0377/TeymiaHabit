import SwiftUI
import SwiftData

struct NewHabitView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    
    // MARK: - Properties
    private let habit: Habit?
    private let template: HabitTemplate?
    private let onSaveCompletion: (() -> Void)?
    
    // MARK: - State
    @State private var title = ""
    @State private var selectedType: HabitType = .count
    @State private var countGoal: Int = 1
    @State private var hours: Int = 1
    @State private var minutes: Int = 0
    @State private var activeDays: [Bool] = Array(repeating: true, count: 7)
    @State private var isReminderEnabled = false
    @State private var reminderTimes: [Date] = [Date()]
    @State private var startDate = Date()
    @State private var selectedIcon: String? = "checkmark"
    @State private var selectedIconColor: HabitIconColor = .primary
    @State private var showPaywall = false
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isCountFocused: Bool
    
    // MARK: - Initialization
    init(habit: Habit? = nil, template: HabitTemplate? = nil, onSaveCompletion: (() -> Void)? = nil) {
        self.habit = habit
        self.template = template
        self.onSaveCompletion = onSaveCompletion
        
        if let habit = habit {
            // Existing habit editing
            _title = State(initialValue: habit.title)
            _selectedType = State(initialValue: habit.type)
            _countGoal = State(initialValue: habit.type == .count ? habit.goal : 1)
            _hours = State(initialValue: habit.type == .time ? habit.goal / 3600 : 1)
            _minutes = State(initialValue: habit.type == .time ? (habit.goal % 3600) / 60 : 0)
            _activeDays = State(initialValue: habit.activeDays)
            _isReminderEnabled = State(initialValue: habit.reminderTimes != nil && !habit.reminderTimes!.isEmpty)
            _reminderTimes = State(initialValue: habit.reminderTimes ?? [Date()])
            _startDate = State(initialValue: habit.startDate)
            _selectedIcon = State(initialValue: habit.iconName ?? "checkmark")
            _selectedIconColor = State(initialValue: habit.iconColor)
        } else if let template = template {
            // Apply template
            _title = State(initialValue: template.name.localized)
            _selectedType = State(initialValue: template.habitType)
            _selectedIcon = State(initialValue: template.icon)
            _selectedIconColor = State(initialValue: template.iconColor)
            
            // Set goal based on type
            if template.habitType == .count {
                _countGoal = State(initialValue: template.defaultGoal)
                _hours = State(initialValue: 1)
                _minutes = State(initialValue: 0)
            } else {
                _countGoal = State(initialValue: 1)
                _hours = State(initialValue: template.defaultGoal / 60)
                _minutes = State(initialValue: template.defaultGoal % 60)
            }
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
    
    private var isKeyboardActive: Bool {
        isTitleFocused || isCountFocused
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Name
                    NameFieldSection(
                        title: $title,
                        isFocused: $isTitleFocused
                    )
                    
                    // Icon
                    IconSection(
                        selectedIcon: $selectedIcon,
                        selectedColor: $selectedIconColor,
                        onShowPaywall: {
                            showPaywall = true
                        }
                    )
                }
                
                // Goal
                GoalSection(
                    selectedType: $selectedType,
                    countGoal: $countGoal,
                    hours: $hours,
                    minutes: $minutes,
                    isFocused: $isCountFocused
                )
                
                Section {
                    // Start Date
                    StartDateSection(startDate: $startDate)
                    
                    // Active Days
                    ActiveDaysSection(activeDays: $activeDays)
                }
                
                // Reminders
                Section {
                    ReminderSection(
                        isReminderEnabled: $isReminderEnabled,
                        reminderTimes: $reminderTimes,
                        onShowPaywall: {
                            showPaywall = true
                        }
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Space for button
                Color.clear.frame(height: 80)
            }
            .navigationTitle(habit == nil ? "create_habit".localized : "edit_habit".localized)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    XmarkView(action: {
                        dismiss()
                    })
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        isTitleFocused = false
                        isCountFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
            
            .overlay(alignment: .bottom) {
                Button {
                    guard isFormValid else { return }
                    saveHabit()
                } label: {
                    HStack(spacing: 8) {
                        Text(habit == nil ? "button_save".localized : "button_save".localized)
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isFormValid ? Color.white : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                isFormValid
                                ? AnyShapeStyle(AppColorManager.shared.selectedColor.adaptiveGradient(for: colorScheme).opacity(0.9))
                                : AnyShapeStyle(LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isFormValid)
                .animation(.easeInOut(duration: 0.25), value: isFormValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Methods
    private func saveHabit() {
        // Validation and correction
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
            // Update existing habit
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
            // Create new habit
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
        
        // Call completion callback if provided, otherwise just dismiss
        if let onSaveCompletion = onSaveCompletion {
            onSaveCompletion()
        } else {
            dismiss()
        }
    }
    
    // Handle notifications when saving
    private func handleNotifications(for habit: Habit) {
        if isReminderEnabled {
            Task {
                // Check permissions using ensureAuthorization
                let isAuthorized = await NotificationManager.shared.ensureAuthorization()
                
                if isAuthorized {
                    let success = await NotificationManager.shared.scheduleNotifications(for: habit)
                    if !success {
                        print("Failed to schedule notifications")
                    }
                } else {
                    // If user denied permissions
                    isReminderEnabled = false
                }
            }
        } else {
            // Cancel existing notifications
            NotificationManager.shared.cancelNotifications(for: habit)
        }
    }
}
