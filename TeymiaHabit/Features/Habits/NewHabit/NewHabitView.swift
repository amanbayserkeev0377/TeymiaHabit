import SwiftUI
import SwiftData

struct NewHabitView: View {
    @Environment(AppDependencyContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: NewHabitViewModel?
    
    let habit: Habit?
    
    // MARK: - Initialization
    
    init(habit: Habit? = nil) {
        self.habit = habit
    }
    
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let vm = viewModel {
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
                                IconPickerView(selectedIcon: $vm.selectedIcon, selectedColor: $vm.selectedIconColor)
                            } label: {
                                HStack {
                                    Label { Text("icon") }
                                    icon: { RowIcon(iconName: "app.background.dotted") }
                                    
                                    Spacer()
                                    
                                    Image(systemName: vm.selectedIcon)
                                        .font(.system(size: 20))
                                        .foregroundStyle(
                                            LinearGradient(colors: [vm.selectedIconColor.lightColor, vm.selectedIconColor.darkColor], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
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
                        CloseToolbarButton()
                        
                        ConfirmationToolbarButton(
                            action: { vm.save() },
                            isDisabled: !vm.isFormValid
                        )
                    }
                }
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = NewHabitViewModel(
                            modelContext: modelContext,
                            notificationManager: appContainer.notificationManager,
                            widgetService: appContainer.widgetService,
                            habit: habit,
                            onSaveCompletion: { dismiss() }
                        )
                    }
            }
        }
    }
}
