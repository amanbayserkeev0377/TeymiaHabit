import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    let date: Date
    
    @Environment(HabitService.self) private var habitService
    @Environment(TimerService.self) private var timerService
    @Environment(WidgetService.self) private var widgetService
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(SoundManager.self) private var soundManager
    @Environment(HabitLiveActivityManager.self) private var habitLiveActivityManager
    
    var body: some View {
        HabitDetailContentView(
            habit: habit,
            date: date,
            viewModel: HabitDetailViewModel(
                habit: habit,
                initialDate: date,
                habitService: habitService,
                timerService: timerService,
                widgetService: widgetService,
                notificationManager: notificationManager,
                soundManager: soundManager,
                habitLiveActivityManager: habitLiveActivityManager
            )
        )
    }
}

struct HabitDetailContentView: View {
    let habit: Habit
    let date: Date
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: HabitDetailViewModel
    @State private var showingStats = false
    @State private var isEditPresented = false
    
    init(
        habit: Habit,
        date: Date,
        viewModel: HabitDetailViewModel
    ) {
        self.habit = habit
        self.date = date
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        @Bindable var vm = viewModel
        mainContent(vm: viewModel)
            .primaryBackground()
            .navigationTitle(habit.title)
            .navigationSubtitle("Goal: \(habit.formattedGoal)")
            .toolbar { toolbarContent(vm: viewModel) }
            .deleteSingleHabitAlert(
                isPresented: $vm.alertState.isDeleteAlertPresented,
                habitName: habit.title,
                onDelete: {
                    viewModel.deleteHabit()
                    dismiss()
                }
            )
            .id(habit.uuid.uuidString)
            .onDisappear { viewModel.prepareForDeletion() }
            .onChange(of: date) { _, newDate in
                viewModel.updateDisplayedDate(newDate)
            }
            .sheet(isPresented: $isEditPresented) {
                    NewHabitView()
            }
            .sheet(isPresented: $showingStats) {
                HabitStatisticsView(habit: habit)
            }
    }
    
    // MARK: - Content
    @ViewBuilder
    private func mainContent(vm: HabitDetailViewModel) -> some View {
        ScrollView {
                Spacer()
                HabitProgressView(viewModel: vm, habit: habit)
                Spacer()
                VStack(spacing: 30) {
                    actionButtonsSection(viewModel: vm)
                    completeButtonView(viewModel: vm)
                        .disabled(vm.isAlreadyCompleted)
                }
                Spacer()
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent(vm: HabitDetailViewModel) -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button { showingStats = true } label: {
                Image(systemName: "chart.bar.fill")
            }
            .tint(.primary)
        }
        ToolbarItem(placement: .primaryAction) {
            menuButton(vm: vm)
        }
    }
    
    // MARK: - Buttons
    @ViewBuilder
    private func menuButton(vm: HabitDetailViewModel) -> some View {
        Menu {
            Button { isEditPresented = true } label: {
                Label("button_edit", systemImage: "pencil")
            }
            Button {
                vm.archiveHabit()
                dismiss()
            } label: {
                Label("archive", systemImage: "archivebox")
            }
            Divider()
            Button(role: .destructive) {
                vm.alertState.isDeleteAlertPresented = true
            } label: {
                Label("button_delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .tint(.primary)
    }
    
    private func actionButtonsSection(viewModel: HabitDetailViewModel) -> some View {
        ActionButtonsSection(
            habit: habit,
            date: date,
            isToday: Calendar.current.isDateInToday(date),
            isTimerRunning: viewModel.isTimerRunning,
            onReset: { viewModel.resetProgress() },
            onTimerToggle: { viewModel.toggleTimer() }
        )
    }
    
    private func completeButtonView(viewModel: HabitDetailViewModel) -> some View {
        Button(action: { viewModel.completeHabit() }) {
            Text(viewModel.isAlreadyCompleted ? "completed" : "complete")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.blackWhite)
                .frame(maxWidth: .infinity, minHeight: 52)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive().tint(habit.actualColor), in: .capsule)
        .padding(.horizontal, DS.Spacing.s24)
    }
}
