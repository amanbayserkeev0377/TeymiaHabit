import SwiftUI
import SwiftData

struct HabitDetailView: View {
    // MARK: - Properties
    let habit: Habit
    let date: Date
    var onDelete: (() -> Void)?
    var onShowStats: (() -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    private var isSmallDevice: Bool {
        UIScreen.main.bounds.width <= 375
    }
    
    // MARK: - State Properties
    @State private var viewModel: HabitDetailViewModel?
    @State private var navigateToStatistics = false
    @State private var isEditPresented = false
    @State private var selectedHabitForStats: Habit? = nil
    
    // CRITICAL: Add explicit observation of TimerService
    @State private var timerService = TimerService.shared
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if let viewModel = viewModel {
                habitDetailContent(viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { habitDetailToolbar }
                    // CRITICAL: Force UI updates when timer state changes
                    .onChange(of: timerService.updateTrigger) { _, _ in
                        // This will trigger recomputation of currentProgress
                        print("🔄 UI Update triggered: \(timerService.updateTrigger)")
                    }
                    .onChange(of: timerService.liveProgress) { _, newProgress in
                        // Force view refresh when progress changes
                        let habitId = habit.uuid.uuidString
                        if let progress = newProgress[habitId] {
                            print("📊 Progress updated for \(habitId): \(progress)")
                        }
                    }
                    .onChange(of: date) { _, newDate in
                        viewModel.saveIfNeeded()
                        setupViewModel(with: newDate)
                    }
                    .onDisappear {
                        viewModel.saveIfNeeded()
                        viewModel.cleanup()
                    }
                    .navigationDestination(item: $selectedHabitForStats) { habit in
                        HabitStatisticsView(habit: habit)
                    }
                    .sheet(isPresented: $isEditPresented) {
                        NewHabitView(habit: habit)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                        viewModel.saveIfNeeded()
                    }
            }
        }
        .onAppear {
            setupViewModel()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func habitDetailContent(viewModel: HabitDetailViewModel) -> some View {
        VStack(spacing: 0) {
            Text(habit.title)
                .font(.largeTitle.bold())
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .padding(.horizontal)
                .padding(.top, 0)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityHeading(.h1)
            
            goalInfoView(viewModel: viewModel)
            
            Spacer().frame(height: isSmallDevice ? 20 : 30)
            
            ProgressControlSection(
                habit: habit,
                currentProgress: .constant(viewModel.currentProgress),
                completionPercentage: viewModel.completionPercentage,
                formattedProgress: habit.formattedProgress(for: date, currentProgress: viewModel.currentProgress),
                onIncrement: viewModel.incrementProgress,
                onDecrement: viewModel.decrementProgress
            )
            
            Spacer().frame(height: isSmallDevice ? 16 : 24)
            
            actionButtonsView(viewModel: viewModel)
            
            if isSmallDevice {
                Spacer().frame(height: 20)
            } else {
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            completeButtonView(viewModel: viewModel)
                .padding(.bottom, isSmallDevice ? 0 : 8)
                .padding(.vertical, isSmallDevice ? 4 : 8)
        }
        .onChange(of: viewModel.alertState.successFeedbackTrigger) { _, newValue in
            if newValue {
                HapticManager.shared.play(.success)
            }
        }
        .onChange(of: viewModel.alertState.errorFeedbackTrigger) { _, newValue in
            if newValue {
                HapticManager.shared.play(.error)
            }
        }
        .countInputAlert(
            isPresented: Binding(
                get: { viewModel.alertState.isCountAlertPresented },
                set: { viewModel.alertState.isCountAlertPresented = $0 }
            ),
            inputText: Binding(
                get: { viewModel.alertState.countInputText },
                set: { viewModel.alertState.countInputText = $0 }
            ),
            successTrigger: Binding(
                get: { viewModel.alertState.successFeedbackTrigger },
                set: { viewModel.alertState.successFeedbackTrigger = $0 }
            ),
            errorTrigger: Binding(
                get: { viewModel.alertState.errorFeedbackTrigger },
                set: { viewModel.alertState.errorFeedbackTrigger = $0 }
            ),
            onCountInput: {
                viewModel.handleCountInput()
                viewModel.alertState.isCountAlertPresented = false
            },
            habit: habit
        )
        .timeInputAlert(
            isPresented: Binding(
                get: { viewModel.alertState.isTimeAlertPresented },
                set: { viewModel.alertState.isTimeAlertPresented = $0 }
            ),
            hoursText: Binding(
                get: { viewModel.alertState.hoursInputText },
                set: { viewModel.alertState.hoursInputText = $0 }
            ),
            minutesText: Binding(
                get: { viewModel.alertState.minutesInputText },
                set: { viewModel.alertState.minutesInputText = $0 }
            ),
            successTrigger: Binding(
                get: { viewModel.alertState.successFeedbackTrigger },
                set: { viewModel.alertState.successFeedbackTrigger = $0 }
            ),
            errorTrigger: Binding(
                get: { viewModel.alertState.errorFeedbackTrigger },
                set: { viewModel.alertState.errorFeedbackTrigger = $0 }
            ),
            onTimeInput: {
                viewModel.handleTimeInput()
                viewModel.alertState.isTimeAlertPresented = false
            },
            habit: habit
        )
        .deleteSingleHabitAlert(
            isPresented: Binding(
                get: { viewModel.alertState.isDeleteAlertPresented },
                set: { viewModel.alertState.isDeleteAlertPresented = $0 }
            ),
            habitName: habit.title,
            onDelete: {
                viewModel.deleteHabit()
                viewModel.alertState.isDeleteAlertPresented = false
                if let onDelete = onDelete {
                    onDelete()
                } else {
                    dismiss()
                }
            },
            habit: habit
        )
    }
    
    // Информация о цели привычки - центрированная с иконкой
    private func goalInfoView(viewModel: HabitDetailViewModel) -> some View {
        VStack(spacing: 8) {
            // Основная информация о цели
            HStack(spacing: 8) {
                // Иконка слева от текста Goal (если она установлена)
                if let iconName = habit.iconName {
                    Image(systemName: iconName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Текст goal по центру
                Text("goal".localized(with: viewModel.formattedGoal))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 8)
    }
    
    // Секция с кнопками действий
    private func actionButtonsView(viewModel: HabitDetailViewModel) -> some View {
        ActionButtonsSection(
            habit: habit,
            isTimerRunning: viewModel.isTimerRunning,
            onReset: {
                viewModel.resetProgress()
                viewModel.alertState.errorFeedbackTrigger.toggle()
            },
            onTimerToggle: {
                print("🎯 Timer button tapped")
                print("🔄 Timer toggle requested from view")
                viewModel.toggleTimer()
            },
            onManualEntry: {
                if habit.type == .time {
                    viewModel.alertState.isTimeAlertPresented = true
                } else {
                    viewModel.alertState.isCountAlertPresented = true
                }
            }
        )
    }
    
    // Complete button с BeautifulButton
    private func completeButtonView(viewModel: HabitDetailViewModel) -> some View {
        Button(action: {
            viewModel.completeHabit()
        }) {
            Text(viewModel.isAlreadyCompleted ? "completed".localized : "complete".localized)
        }
        .beautifulButton(
            habit: habit,
            isEnabled: !viewModel.isAlreadyCompleted,
            lightOpacity: 0.8,
            darkOpacity: 1.0
        )
        .modifier(HapticManager.shared.sensoryFeedback(.impact(weight: .medium), trigger: !viewModel.isAlreadyCompleted))
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }
    
    // Toolbar
    @ToolbarContentBuilder
    private var habitDetailToolbar: some ToolbarContent {
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                selectedHabitForStats = habit
            } label: {
                Image(systemName: "chart.line.text.clipboard")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(habit.iconColor.color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(habit.iconColor.adaptiveGradient(for: colorScheme)
                                .opacity(0.1))
                    )
            }
        }
        
        // Меню с действиями справа
        ToolbarItem(placement: .primaryAction) {
            Menu {
                // Кнопка редактирования
                Button {
                    isEditPresented = true
                } label: {
                    Label("button_edit".localized, systemImage: "pencil")
                }
                .withHabitTint(habit)
                
                // Кнопка архивирования
                Button {
                    archiveHabit()
                } label: {
                    Label("archive".localized, systemImage: "archivebox")
                }
                .withHabitTint(habit)
                
                // Кнопка удаления
                Button(role: .destructive) {
                    viewModel?.alertState.isDeleteAlertPresented = true
                } label: {
                    Label("button_delete".localized, systemImage: "trash")
                }
                .tint(.red)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(habit.iconColor.color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(habit.iconColor.adaptiveGradient(for: colorScheme)
                                .opacity(0.1))
                    )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupViewModel(with newDate: Date? = nil) {
        viewModel?.saveIfNeeded()
        viewModel?.cleanup()
        
        let vm = HabitDetailViewModel(
            habit: habit,
            date: newDate ?? date,
            modelContext: modelContext
        )
        vm.onHabitDeleted = onDelete
        viewModel = vm
    }
    
    private func archiveHabit() {
        habit.isArchived = true
        try? modelContext.save()
        HapticManager.shared.play(.success)
        
        if let onDelete = onDelete {
            onDelete()
        } else {
            dismiss()
        }
    }
}
