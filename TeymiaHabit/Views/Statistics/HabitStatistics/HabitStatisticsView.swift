import SwiftUI
import SwiftData

struct HabitStatisticsView: View {
    // MARK: - Properties
    
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ProManager.self) private var proManager
    
    // MARK: - State
    
    @State private var selectedDate: Date = Date()
    @State private var viewModel: HabitStatsViewModel
    @State private var detailViewModel: HabitDetailViewModel?
    @State private var showingResetAlert = false
    @State private var alertState = AlertState()
    @State private var updateCounter = 0
    @State private var showingPaywall = false
    @State private var showingCountInput = false
    @State private var showingTimeInput = false
    @State private var barChartTimeRange: ChartTimeRange = .week
    
    // MARK: - Initialization
    init(habit: Habit) {
        self.habit = habit
        self._viewModel = State(initialValue: HabitStatsViewModel(habit: habit))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ZStack {
                        MonthlyCalendarView(
                            habit: habit,
                            selectedDate: $selectedDate,
                            updateCounter: updateCounter,
                            onActionRequested: handleCalendarAction,
                            showingCountInput: $showingCountInput,
                            showingTimeInput: $showingTimeInput,
                            onCountInput: { count, date in
                                alertState.date = date
                                handleCustomCountInput(count: count)
                            },
                            onTimeInput: { hours, minutes, date in
                                alertState.date = date
                                handleCustomTimeInput(hours: hours, minutes: minutes)
                            }
                        )
                        
                        if !proManager.isPro {
                            ProStatisticsOverlay {
                                showingPaywall = true
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                } footer: {
                    HStack(spacing: 8) {
                        Image("cursor")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.secondary)
                        Text("tap_dates".localized)
                            .font(.footnote)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .listRowBackground(Color.mainRowBackground)
                
                Section {
                    ZStack {
                        VStack(spacing: 16) {
                            TimeRangePicker(selection: $barChartTimeRange)
                            
                            barChartContent
                                .animation(.easeInOut(duration: 0.4), value: barChartTimeRange)
                        }
                        
                        if !proManager.isPro {
                            ProStatisticsOverlay {
                                showingPaywall = true
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                } footer: {
                    HStack(spacing: 8) {
                        Image("cursor")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.secondary)
                        Text("press_hold_bars".localized)
                            .font(.footnote)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .listRowBackground(Color.mainRowBackground)
                
                Section {
                    // Start date
                    HStack {
                        Image("calendar")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.primary)
                        Text("start_date".localized)
                        
                        Spacer()
                        
                        Text(dateFormatter.string(from: habit.startDate))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image("trophy")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.primary)
                        Text("daily_goal".localized)
                        
                        Spacer()
                        
                        Text(habit.formattedGoal)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image("calendar.wed")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.primary)
                        Text("active_days".localized)
                        
                        Spacer()
                        
                        Text(formattedActiveDays)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color.mainRowBackground)
                
                Section {
                    Button {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image("home.maintenance")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.primary)
                            Text("reset_all_history".localized)
                        }
                    }
                    .tint(.primary)
                    
                    Button(role: .destructive) {
                        alertState.isDeleteAlertPresented = true
                    } label: {
                        HStack {
                            Image("trash")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.red.gradient)
                            Text("delete_habit".localized)
                        }
                    }
                }
                .listRowBackground(Color.mainRowBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.mainGroupBackground)
            .navigationTitle(habit.title)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onChange(of: updateCounter) { _, _ in
                viewModel.refresh()
            }
            .onChange(of: alertState.successFeedbackTrigger) { _, newValue in
                if newValue {
                    HapticManager.shared.play(.success)
                }
            }
            .onChange(of: alertState.errorFeedbackTrigger) { _, newValue in
                if newValue {
                    HapticManager.shared.play(.error)
                }
            }
            .deleteSingleHabitAlert(
                isPresented: $alertState.isDeleteAlertPresented,
                habitName: habit.title,
                onDelete: deleteHabit,
                habit: habit
            )
            .alert("alert_reset_history", isPresented: $showingResetAlert) {
                Button("button_cancel".localized, role: .cancel) { }
                Button("button_reset".localized, role: .destructive) {
                    resetHabitHistory()
                }
            } message: {
                Text("alert_reset_history_message".localized)
            }
            .withHabitTint(habit)
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
    }
    
    // MARK: - Bar Chart Content
    
    @ViewBuilder
    private var barChartContent: some View {
        switch barChartTimeRange {
        case .week:
            WeeklyHabitChart(habit: habit, updateCounter: updateCounter)
                .padding(.vertical, 8)
                .transition(.opacity)
            
        case .month:
            MonthlyHabitChart(habit: habit, updateCounter: updateCounter)
                .padding(.vertical, 8)
                .transition(.opacity)
            
        case .year:
            YearlyHabitChart(habit: habit, updateCounter: updateCounter)
                .padding(.vertical, 8)
                .transition(.opacity)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleCalendarAction(_ action: CalendarAction, date: Date) {
        switch action {
        case .complete:
            completeHabitDirectly(for: date)
        case .addProgress:
            alertState.date = date
            
            if habit.type == .count {
                showingCountInput = true
            } else {
                showingTimeInput = true
            }
        case .resetProgress:
            resetProgressDirectly(for: date)
        }
    }
    
    private var formattedActiveDays: String {
        let weekdays = Calendar.userPreferred.orderedFormattedWeekdaySymbols
        
        let activeDaysWithIndex = zip(habit.activeDays.indices, habit.activeDays)
            .filter { $0.1 }
            .map { (weekdays[$0.0], $0.0) }
        
        if activeDaysWithIndex.count == 7 {
            return "everyday".localized
        } else {
            let sortedDays = activeDaysWithIndex.sorted { $0.1 < $1.1 }
            return sortedDays.map { $0.0 }.joined(separator: ", ")
        }
    }
    
    private func completeHabitDirectly(for date: Date) {
        habit.complete(for: date, modelContext: modelContext)
        saveAndRefresh()
        HapticManager.shared.play(.success)
        SoundManager.shared.playCompletionSound()
    }
    
    private func handleCustomCountInput(count: Int) {
        guard let date = alertState.date else { return }
        
        habit.addToProgress(count, for: date, modelContext: modelContext)
        saveAndRefresh()
        alertState.successFeedbackTrigger.toggle()
    }
    
    private func handleCustomTimeInput(hours: Int, minutes: Int) {
        guard let date = alertState.date else { return }
        let totalSeconds = (hours * 3600) + (minutes * 60)
        
        guard totalSeconds > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        habit.addToProgress(totalSeconds, for: date, modelContext: modelContext)
        saveAndRefresh()
        alertState.successFeedbackTrigger.toggle()
    }
    
    private func resetProgressDirectly(for date: Date) {
        habit.resetProgress(for: date, modelContext: modelContext)
        saveAndRefresh()
        HapticManager.shared.play(.error)
    }
    
    private func saveAndRefresh() {
        try? modelContext.save()
        viewModel.refresh()
        updateCounter += 1
    }
    
    private func resetHabitHistory() {
        guard let completions = habit.completions else { return }
        
        for completion in completions {
            modelContext.delete(completion)
        }
        
        habit.completions = []
        try? modelContext.save()
        viewModel.refresh()
        updateCounter += 1
    }
    
    private func deleteHabit() {
        NotificationManager.shared.cancelNotifications(for: habit)
        modelContext.delete(habit)
        HapticManager.shared.play(.error)
        dismiss()
    }
    
    // MARK: - Formatters
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}
