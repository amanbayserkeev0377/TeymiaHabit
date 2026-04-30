import SwiftUI
import SwiftData

struct NewHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(WidgetService.self) private var widgetService
    
    var habit: Habit? = nil
    
    var body: some View {
        NewHabitContentView(
            habit: habit,
            modelContext: modelContext,
            notificationManager: notificationManager,
            widgetService: widgetService
        )
    }
    
}

struct NewHabitContentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: NewHabitViewModel

    // MARK: - Init
    init(
        habit: Habit?,
        modelContext: ModelContext,
        notificationManager: NotificationManager,
        widgetService: WidgetService
    ) {
        _viewModel = State(wrappedValue: NewHabitViewModel(
            modelContext: modelContext,
            notificationManager: notificationManager,
            widgetService: widgetService,
            habit: habit
        ))
    }
    
    // MARK: - Body
    var body: some View {
        @Bindable var vm = viewModel
        habitForm(vm: vm)
            .navigationTitle(vm.habit == nil ? "create_habit" : "edit_habit")
//            .navigationBarTitleDisplayMode(.inline) TODO
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                CloseToolbarButton(dismiss: {
                    dismiss()
                })
                ConfirmationToolbarButton(
                    action: {
                        vm.save()
                        dismiss()
                    },
                    isDisabled: !vm.isFormValid
                )
            }
    }
    
    // MARK: - Form
    @ViewBuilder
    private func habitForm(vm: NewHabitViewModel) -> some View {
        @Bindable var vm = vm
        Form {
            Section {
                Label {
                    TextField("habit_name", text: $vm.title)
                        .fontWeight(.medium)
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
                            .frame(size: DS.Icon.s20)
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
        .formStyle(.grouped)
    }
    
}
