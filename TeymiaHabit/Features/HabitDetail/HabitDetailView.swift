import SwiftUI
import SwiftData
import AVFoundation

struct HabitDetailView: View {
    let habit: Habit
    let date: Date
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ProManager.self) private var proManager
    @Environment(TimerService.self) private var timerService
    
    @State private var viewModel: HabitDetailViewModel?
    @State private var statsViewModel: HabitStatsViewModel
    
    @State private var selectedDate: Date = Date()
    @State private var updateCounter = 0
    @State private var isEditPresented = false
    @State private var showingResetAlert = false
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
                ScrollView(.vertical, showsIndicators: false) {
                    mainStackContent
                }
                .preferredColorScheme(.dark)
                .id(habit.uuid.uuidString)
                .onChange(of: timerService.updateTrigger) { _, _ in
                    if timerService.isTimerRunning(for: habit.uuid.uuidString) {
                        viewModel?.refresh()
                    }
                }
                .modifier(HabitDetailLifecycleModifier(
                    viewModel: viewModel,
                    statsViewModel: statsViewModel,
                    updateCounter: updateCounter,
                    alertState: $alertState,
                    date: date,
                    setupViewModel: setupViewModel
                ))
                .modifier(HabitDetailDialogsModifier(
                    isEditPresented: $isEditPresented,
                    habit: habit,
                    viewModel: viewModel
                ))
                .safeAreaBar(edge: .top) {
                    dragIndicator
                }
                .safeAreaBar(edge: .bottom) {
                    VStack {
                        if let vm = viewModel {
                            actionButtonsSection(viewModel: vm).padding(.bottom, 10)
                            if !vm.isAlreadyCompleted{
                                completeButtonView(viewModel: vm).padding(.bottom, 16)
                            }
                        }
                    }
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
    
    // MARK: - Sub-Stacks
    private var mainStackContent: some View {
        VStack(spacing: 40) {
            contentView
            
            habitTitle
                .padding(.top, 24)
            
            StreaksView(viewModel: statsViewModel)
            
            calendarBlock
                .background(liquidGlassBackground)
            
            chartBlock
                .background(liquidGlassBackground)
                .padding(.bottom, 50)
        }
        .padding(.top, 70)
        .padding(.horizontal, 20)
    }
    
    private var liquidGlassBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.white.opacity(0.15).gradient)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.15),
                                .white.opacity(0.15),
                                .white.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    private var dragIndicator: some View {
        Capsule()
            .fill(.white.opacity(0.6))
            .frame(width: 55, height: 5)
            .padding(.top, 8)
    }
    
    private var habitTitle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary.gradient)
                Text("goal \(habit.formattedGoal)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7).gradient)
            }
            
            Spacer()
            
            menuButton
        }
    }
    
    // MARK: - Content Blocks
    
    private var chartBlock: some View {
        ZStack {
            VStack(spacing: 30) {
                TimeRangePicker(selection: $barChartTimeRange)
                    .padding(.horizontal, 16)
                
                barChartContent.frame(height: 240)
            }
        }
    }
    
    private var calendarBlock: some View {
        ZStack {
            MonthlyCalendarView(
                habit: habit,
                selectedDate: $selectedDate,
                updateCounter: updateCounter,
                onActionRequested: handleCalendarAction,
                onCountInput: { val, date in
                    alertState.date = date
                    handleCustomCountInput(count: val)
                },
                onTimeInput: { h, m, date in
                    alertState.date = date
                    handleCustomTimeInput(hours: h, minutes: m)
                }
            )
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            if let viewModel = viewModel {
                HabitProgressView(viewModel: viewModel, habit: habit)
            }
        }.frame(maxWidth: .infinity)
    }
    
    // MARK: - Buttons
    private var menuButton: some View {
        Menu {
            Button { viewModel?.toggleSkip() } label: {
                Label(viewModel?.isSkipped == true ? "unskip" : "skip",
                      systemImage: viewModel?.isSkipped == true ? "arrow.left" : "arrow.right")
            }
            Button { isEditPresented = true } label: { Label("button_edit", systemImage: "pencil") }
            Button { archiveHabit() } label: { Label("archive", systemImage: "archivebox") }
            Divider()
            Button(role: .destructive) { viewModel?.alertState.isDeleteAlertPresented = true } label: {
                Label("button_delete", systemImage: "trash")
            }
            .tint(.red)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.primary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(.white.opacity(0.15))
                )
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
        .padding(.bottom, 10)
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
    
    @ViewBuilder
    private var barChartContent: some View {
        switch barChartTimeRange {
        case .week: WeeklyHabitChart(habit: habit, updateCounter: updateCounter)
        case .month: MonthlyHabitChart(habit: habit, updateCounter: updateCounter)
        case .year: YearlyHabitChart(habit: habit, updateCounter: updateCounter)
        }
    }
    
    private func handleCalendarAction(_ action: CalendarAction, date: Date) {
        switch action {
        case .complete: habit.complete(for: date, modelContext: modelContext); saveAndRefreshStats()
        case .resetProgress: habit.resetProgress(for: date, modelContext: modelContext); saveAndRefreshStats()
        }
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
}

// MARK: - Modifiers
private struct HabitDetailLifecycleModifier: ViewModifier {
    let viewModel: HabitDetailViewModel?
    let statsViewModel: HabitStatsViewModel
    let updateCounter: Int
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
