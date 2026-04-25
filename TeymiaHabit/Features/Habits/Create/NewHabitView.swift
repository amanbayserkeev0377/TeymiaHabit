import SwiftUI
import SwiftData

struct NewHabitView: View {
    @Environment(AppDependencyContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let habit: Habit?
    @State private var viewModel: NewHabitViewModel?
    
    // MARK: - Initialization
    init(habit: Habit? = nil) {
        self.habit = habit
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if let viewModel {
                @Bindable var vm = viewModel
                habitForm(vm: vm)
            }
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = NewHabitViewModel(
                modelContext: modelContext,
                notificationManager: appContainer.notificationManager,
                widgetService: appContainer.widgetService,
                habit: habit,
                onSaveCompletion: { dismiss() }
            )
        }
    }
    
    // MARK: - Form
    @ViewBuilder
    private func habitForm(vm: NewHabitViewModel) -> some View {
        @Bindable var vm = vm
        NavigationStack {
            List {
                Section {
                    Label {
                        TextField("habit_name", text: $vm.title)
                            .fontWeight(.medium)
                            .submitLabel(.done)
                    } icon: { RowIcon(iconName: "pencil") }
                    
                    NavigationLink {
                        IconPickerView(
                            selectedIcon: $vm.selectedIcon,
                            selectedColor: $vm.selectedIconColor,
                            hexColor: $vm.selectedHexColor
                        )
                    } label: {
                        HStack {
                            Label { Text("icon") }
                            icon: { RowIcon(iconName: "app.background.dotted") }
                            Spacer()
                            Image(vm.selectedIcon)
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(vm.actualColor)
                        }
                    }
                }
                
                Section {
                    GoalSection(
                        selectedType: $vm.selectedType,
                        countGoal: $vm.countGoal,
                        hours: $vm.hours,
                        minutes: $vm.minutes
                    )
                }
                
                Section {
                    RepeatDaysView(activeDays: $vm.activeDays)
                    StartDateSection(startDate: $vm.startDate)
                    ReminderSection(
                        isReminderEnabled: $vm.isReminderEnabled,
                        reminderTimes: $vm.reminderTimes
                    )
                }
            }
            .navigationTitle(vm.habit == nil ? "create_habit" : "edit_habit")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                CloseToolbarButton(dismiss: { dismiss() })
                ConfirmationToolbarButton(
                    action: { vm.save() },
                    isDisabled: !vm.isFormValid
                )
            }
        }
    }
}
