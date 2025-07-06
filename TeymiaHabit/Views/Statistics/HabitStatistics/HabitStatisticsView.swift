import SwiftUI
import SwiftData

struct HabitStatisticsView: View {
    // MARK: - Properties
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    
    // MARK: - State
    @State private var selectedDate: Date = Date()
    @State private var viewModel: HabitStatsViewModel
    @State private var detailViewModel: HabitDetailViewModel?
    @State private var showingResetAlert = false
    @State private var alertState = AlertState()
    @State private var updateCounter = 0
    @State private var isTimeInputPresented: Bool = false
    
    // 🔥 NEW: Separate time range controls for each section
    @State private var barChartTimeRange: ChartTimeRange = .month
    @State private var lineChartTimeRange: ChartTimeRange = .week
    
    // MARK: - Initialization
    init(habit: Habit) {
        self.habit = habit
        self._viewModel = State(initialValue: HabitStatsViewModel(habit: habit))
    }
    
    // MARK: - Body
    var body: some View {
        List {
            // Streaks
            StreaksView(viewModel: viewModel)
            
            // Monthly Calendar
            Section {
                MonthlyCalendarView(
                    habit: habit,
                    selectedDate: $selectedDate,
                    updateCounter: updateCounter,
                    onActionRequested: handleCalendarAction
                )
                .listRowInsets(EdgeInsets())
                .frame(maxWidth: .infinity)
            } footer: {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap")
                        .font(.footnote)
                        .withHabitColor(habit)
                    Text("habit_statistics_view".localized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
            .listSectionSeparator(.hidden)
            
            // 🔥 NEW: Bar Charts Section
            Section {
                VStack(spacing: 16) {
                    // 3D Illustration + Description
                    barChartsHeader
                    
                    // Time Range Picker for Bar Charts
                    TimeRangePicker(selection: $barChartTimeRange)
                    
                    // Bar Chart Display
                    barChartContent
                        .animation(.easeInOut(duration: 0.4), value: barChartTimeRange)
                }
            } header: {
                Text("Interactive Analysis")
                    .font(.headline)
            }
            .listSectionSeparator(.hidden)
            
            // 🔥 NEW: Line Charts Section
            Section {
                VStack(spacing: 16) {
                    // 3D Illustration + Description
                    lineChartsHeader
                    
                    // Time Range Picker for Line Charts
                    TimeRangePicker(selection: $lineChartTimeRange)
                    
                    // Line Chart Display
                    lineChartContent
                        .animation(.easeInOut(duration: 0.4), value: lineChartTimeRange)
                }
            } header: {
                Text("Trend Analysis")
                    .font(.headline)
            }
            .listSectionSeparator(.hidden)
            
            // Habit Details Section
            Section("Details") {
                // Start date
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .withHabitColor(habit)
                    Text("start_date".localized)
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: habit.startDate))
                        .foregroundStyle(.secondary)
                }
                
                // Goal
                HStack {
                    Image(systemName: "trophy")
                        .withHabitColor(habit)
                    Text("daily_goal".localized)
                    
                    Spacer()
                    
                    Text(habit.formattedGoal)
                        .foregroundStyle(.secondary)
                }
                
                // Active days
                HStack {
                    Image(systemName: "cloud.sun")
                        .withHabitColor(habit)
                    Text("active_days".localized)
                    
                    Spacer()
                    
                    Text(formattedActiveDays)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Actions Section
            Section {
                Button {
                    showingResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            .withHabitColor(habit)
                        Text("reset_all_history".localized)
                    }
                }
                .tint(.primary)
                
                Button(role: .destructive) {
                    alertState.isDeleteAlertPresented = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                        Text("delete_habit".localized)
                    }
                }
            }
        }
        .navigationTitle(habit.title)
        .navigationBarTitleDisplayMode(.large)
        // Change handlers
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
        // Alerts
        .countInputAlert(
            isPresented: $alertState.isCountAlertPresented,
            inputText: $alertState.countInputText,
            successTrigger: $alertState.successFeedbackTrigger,
            errorTrigger: $alertState.errorFeedbackTrigger,
            onCountInput: { handleCountInput() },
            habit: habit
        )
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
        .overlay {
            if isTimeInputPresented {
                TimeInputView(
                    habit: habit,
                    isPresented: $isTimeInputPresented,
                    onConfirm: { hours, minutes in
                        handleCustomTimeInput(hours: hours, minutes: minutes)
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.spring(duration: 0.3), value: isTimeInputPresented)
            }
        }
    }
    
    // MARK: - 🎨 Bar Charts Header with 3D Illustration
    
    @ViewBuilder
    private var barChartsHeader: some View {
        HStack(spacing: 16) {
                // 3D Bar Chart Icon
                Image("3d_bar_chart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 90)
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Interactive Period Analysis")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("Navigate through current weeks, months, and years with detailed breakdowns")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 🎨 Line Charts Header with 3D Illustration
    
    @ViewBuilder
    private var lineChartsHeader: some View {
        HStack(spacing: 16) {
            // 3D Line Chart Illustration
            Image("3d_line_chart")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Progress Trends")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("Track your consistency patterns over recent periods")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 📊 Bar Chart Content
    
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
    
    // MARK: - 📈 Line Chart Content
    
    @ViewBuilder
    private var lineChartContent: some View {
        switch lineChartTimeRange {
        case .week:
            WeeklyHabitLineChart(habit: habit)
                .padding(.vertical, 8)
                .transition(.opacity)
                
        case .month:
            MonthlyHabitLineChart(habit: habit)
                .padding(.vertical, 8)
                .transition(.opacity)
                
        case .year:
            YearlyHabitLineChart(habit: habit)
                .padding(.vertical, 8)
                .transition(.opacity)
        }
    }
    
    // MARK: - Helper Methods (остаются без изменений)
    
    private func handleCalendarAction(_ action: CalendarAction, date: Date) {
        switch action {
        case .complete:
            completeHabitDirectly(for: date)
        case .addProgress:
            alertState.date = date
            
            if habit.type == .count {
                alertState.isCountAlertPresented = true
            } else {
                isTimeInputPresented = true
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
    
    // Остальные методы остаются без изменений...
    private func completeHabitDirectly(for date: Date) {
        let tempViewModel = HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: modelContext,
        )
        
        tempViewModel.completeHabit()
        tempViewModel.saveIfNeeded()
        viewModel.refresh()
        HapticManager.shared.play(.success)
        updateCounter += 1
    }
    
    private func handleCountInput() {
        guard let date = alertState.date, let count = Int(alertState.countInputText), count > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            alertState.countInputText = ""
            return
        }
        
        let tempViewModel = HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: modelContext,
        )
        
        tempViewModel.alertState.countInputText = alertState.countInputText
        tempViewModel.handleCountInput()
        tempViewModel.saveIfNeeded()
        viewModel.refresh()
        updateCounter += 1
        alertState.countInputText = ""
    }
    
    private func handleCustomTimeInput(hours: Int, minutes: Int) {
        guard let date = alertState.date else { return }
        let totalSeconds = (hours * 3600) + (minutes * 60)
        
        if totalSeconds == 0 {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        let tempViewModel = HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: modelContext
        )
        
        tempViewModel.handleCustomTimeInput(hours: hours, minutes: minutes)
        tempViewModel.saveIfNeeded()
        viewModel.refresh()
        updateCounter += 1
        alertState.successFeedbackTrigger.toggle()
    }
    
    private func resetProgressDirectly(for date: Date) {
        let tempViewModel = HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: modelContext,
        )
        
        tempViewModel.resetProgress()
        tempViewModel.saveIfNeeded()
        viewModel.refresh()
        HapticManager.shared.play(.error)
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
