import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    let date: Date
    
    @Environment(HabitService.self) private var habitService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: HabitDetailViewModel
    @State private var showingStats = false
    @State private var isEditPresented = false
    
    // MARK: - Init
    init(habit: Habit, date: Date, modelContext: ModelContext, appContainer: AppDependencyContainer) {
        self.habit = habit
        self.date = date
        _viewModel = State(wrappedValue: HabitDetailViewModel(
            habit: habit,
            initialDate: date,
            modelContext: modelContext,
            appContainer: appContainer
        )
        )
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            mainContent(vm: viewModel)
                .navigationTitle(habit.title)
                .navigationSubtitle("Goal: \(habit.formattedGoal)")
                .toolbar {
                    toolbarContent(vm: viewModel)
                }
                .deleteSingleHabitAlert(
                    isPresented: $viewModel.alertState.isDeleteAlertPresented,
                    habitName: habit.title,
                    onDelete: deleteHabit
                )
                .id(habit.uuid.uuidString)
                .onDisappear {
                    viewModel.prepareForDeletion()
                }
                .onChange(of: date) { _, newDate in
                    viewModel.updateDisplayedDate(newDate)
                }
                .sheet(isPresented: $isEditPresented) {
                    NewHabitView(habit: habit)
                }
                .sheet(isPresented: $showingStats) {
                    HabitStatisticsView(habit: habit)
                }
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private func mainContent(vm: HabitDetailViewModel) -> some View {
        VStack(spacing: 0) {
            Spacer()
            HabitProgressView(viewModel: vm, habit: habit)
            Spacer()
            VStack(spacing: 30) {
                actionButtonsSection(viewModel: vm)
                completeButtonView(viewModel: vm).disabled(vm.isAlreadyCompleted)
            }
            Spacer()
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent(vm: HabitDetailViewModel) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingStats = true
            } label: {
                Image(systemName: "chart.bar.fill")
            }
            .tint(.primary)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            menuButton(vm: vm)
        }
    }
    
    // MARK: - Buttons
    @ViewBuilder
    private func menuButton(vm: HabitDetailViewModel) -> some View {
        Menu {
            Button {
                isEditPresented = true
            } label: {
                Label("button_edit", systemImage: "pencil")
            }
            
            Button {
                archiveHabit()
            } label: {
                Label("archive", systemImage: "archivebox")
            }
            
            Divider()
            
            Button(role: .destructive) {
                vm.alertState.isDeleteAlertPresented = true
            } label: {
                Label("button_delete", systemImage: "trash")
            }.tint(.red)
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
            HStack {
                Text(viewModel.isAlreadyCompleted ? "completed" : "complete")
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.primaryInverse)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive().tint(.primary), in: .capsule)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Actions
    private func archiveHabit() {
        habitService.archive(habit, context: modelContext)
        dismiss()
    }
    
    private func deleteHabit() {
        viewModel.prepareForDeletion()
        dismiss()
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            habitService.delete(habit, context: modelContext)
        }
    }
}
