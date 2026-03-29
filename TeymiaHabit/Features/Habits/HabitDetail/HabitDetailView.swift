import SwiftUI
import SwiftData
import AVFoundation

struct HabitDetailView: View {
    let habit: Habit
    let date: Date
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(TimerService.self) private var timerService
    
    @State private var viewModel: HabitDetailViewModel?
    @State private var statsViewModel: HabitStatsViewModel
    @State private var showingStats = false
    @State private var selectedDate: Date = Date()
    @State private var isEditPresented = false
    @State private var alertState = AlertState()
    @State private var barChartTimeRange: ChartTimeRange = .week
    
    // MARK: - Init
    init(habit: Habit, date: Date) {
        self.habit = habit
        self.date = date
        self._statsViewModel = State(initialValue: HabitStatsViewModel(habit: habit))
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if habit.modelContext != nil {
                VStack(spacing: 0) {
                    Spacer()
                    
                    if let vm = viewModel {
                        HabitProgressView(viewModel: vm, habit: habit)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 30) {
                        if let vm = viewModel {
                            actionButtonsSection(viewModel: vm)
                            
                            completeButtonView(viewModel: vm)
                                .disabled(vm.isAlreadyCompleted)
                        }
                    }
                    
                    Spacer()
                    Spacer()
                }
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity, alignment: .center)
                .navigationTitle(habit.title)
                .navigationSubtitle("Goal: \(habit.formattedGoal)")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showingStats = true } label: {
                            Label("Show Statistics", systemImage: "chart.bar")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) { menuButton }
                }
                .id(habit.uuid.uuidString)
                .onChange(of: timerService.updateTrigger) { _, _ in
                    if timerService.isTimerRunning(for: habit.uuid.uuidString) {
                        viewModel?.refresh()
                    }
                }
                .modifier(HabitDetailLifecycleModifier(
                    viewModel: viewModel,
                    statsViewModel: statsViewModel,
                    alertState: $alertState,
                    date: date,
                    setupViewModel: setupViewModel
                ))
                .modifier(HabitDetailDialogsModifier(
                    isEditPresented: $isEditPresented,
                    habit: habit,
                    viewModel: viewModel
                ))
                .sheet(isPresented: $showingStats) {
                    HabitStatisticsView(
                        statsViewModel: statsViewModel,
                        selectedDate: $selectedDate,
                        barChartTimeRange: $barChartTimeRange,
                        habit: habit
                    )
                }
                .deleteSingleHabitAlert(
                    isPresented: deleteAlertBinding,
                    habitName: habit.title,
                    onDelete: deleteHabit,
                    habit: habit
                )
            } else {
                Color.clear
            }
        }
    }
        
    // MARK: - Buttons
    private var menuButton: some View {
        Menu {
            Button(role: .destructive) { viewModel?.alertState.isDeleteAlertPresented = true } label: {
                Label("button_delete", systemImage: "trash")
            }
            .tint(.red)
            
            Divider()
            
            Button { viewModel?.toggleSkip() } label: {
                Label(viewModel?.isSkipped == true ? "unskip" : "skip",
                      systemImage: viewModel?.isSkipped == true ? "arrow.left" : "arrow.right")
            }
            Button { isEditPresented = true } label: { Label("button_edit", systemImage: "pencil") }
            Button { archiveHabit() } label: { Label("archive", systemImage: "archivebox") }
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
            onTimerToggle: { viewModel.toggleTimer() },
            onManualCount: { count in
                alertState.date = date
                handleCustomCountInput(count: count)
            },
            onManualTime: { h, m in
                alertState.date = date
                handleCustomTimeInput(hours: h, minutes: m)
            }
        )
    }
    
    private func completeButtonView(viewModel: HabitDetailViewModel) -> some View {
        Button(action: {
            if !viewModel.isAlreadyCompleted { HapticManager.shared.playImpact(.medium) }
            viewModel.completeHabit()
        }) {
            HStack {
                Text(viewModel.isAlreadyCompleted ? "completed" : "complete")
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.primaryInverse)
            .frame(maxWidth: .infinity).frame(height: 52).contentShape(Capsule())
            .background(
                LinearGradient(
                    colors: [
                        habit.iconColor.lightColor,
                        habit.iconColor.darkColor
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: .capsule
            )
        }
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive(), in: .capsule)
        .padding(.horizontal, 24)
    }
    
    private func handleCustomCountInput(count: Int) {
        let targetDate = alertState.date ?? Date()
        
        habit.addToProgress(count, for: targetDate, modelContext: modelContext)
        saveAndRefreshStats()
        HapticManager.shared.play(.success)
        alertState.successFeedbackTrigger = true
    }
    
    private func handleCustomTimeInput(hours: Int, minutes: Int) {
        let targetDate = alertState.date ?? Date()
        let totalValue = (hours * 3600) + (minutes * 60)
        
        habit.addToProgress(totalValue, for: targetDate, modelContext: modelContext)
        saveAndRefreshStats()
        
        HapticManager.shared.play(.success)
        alertState.successFeedbackTrigger = true
    }
    
    private func saveAndRefreshStats() {
        try? modelContext.save()
        viewModel?.refresh()
        statsViewModel.refresh()
    }
    
    // MARK: - Helpers
    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.alertState.isDeleteAlertPresented ?? false },
            set: { viewModel?.alertState.isDeleteAlertPresented = $0 }
        )
    }
    
    private func setupViewModel() {
        if viewModel == nil {
            let vm = HabitDetailViewModel(habit: habit, initialDate: date, modelContext: modelContext)
            vm.onHabitDeleted = { dismiss() }
            viewModel = vm
        }
    }
    
    private func archiveHabit() {
        habit.isArchived = true
        try? modelContext.save()
        HapticManager.shared.play(.success)
        dismiss()
    }
    private func deleteHabit() {
        viewModel?.prepareForDeletion()
        dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            HabitService.shared.delete(habit, context: modelContext)
        }
    }
}

// MARK: - Modifiers
private struct HabitDetailLifecycleModifier: ViewModifier {
    let viewModel: HabitDetailViewModel?
    let statsViewModel: HabitStatsViewModel
    @Binding var alertState: AlertState
    let date: Date
    let setupViewModel: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear(perform: setupViewModel)
            .onAppear {
                viewModel?.onDataSaved = {
                    statsViewModel.refresh()
                }
            }
            .onChange(of: date) { _, n in viewModel?.updateDisplayedDate(n) }
            .onChange(of: alertState.successFeedbackTrigger) { _, v in if v { HapticManager.shared.play(.success) } }
            .onChange(of: alertState.errorFeedbackTrigger) { _, v in if v { HapticManager.shared.play(.error) } }
            .onDisappear {
                viewModel?.prepareForDeletion()
            }
    }
}

private struct HabitDetailDialogsModifier: ViewModifier {
    @Binding var isEditPresented: Bool
    let habit: Habit
    let viewModel: HabitDetailViewModel?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isEditPresented) { NewHabitView(habit: habit).presentationSizing(.page) }
    }
}
