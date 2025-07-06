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
    
    // ✅ НОВЫЙ ПОДХОД: Локальный State для мгновенного UI отклика
    @State private var optimisticProgress: Int = 0
    @State private var isProcessingUpdate: Bool = false
    
    // CRITICAL: Add explicit observation of TimerService
    @State private var timerService = TimerService.shared
    
    // MARK: - Computed Properties
    
    /// ✅ Используем optimistic progress для немедленного отображения
    private var displayProgress: Int {
        return optimisticProgress
    }
    
    private var displayCompletionPercentage: Double {
        habit.goal > 0 ? Double(displayProgress) / Double(habit.goal) : 0
    }
    
    private var displayFormattedProgress: String {
        habit.formattedProgress(for: date, currentProgress: displayProgress)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if let viewModel = viewModel {
                habitDetailContent(viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { habitDetailToolbar }
                    // CRITICAL: Force UI updates when timer state changes
                    .onChange(of: timerService.updateTrigger) { _, _ in
                        updateOptimisticProgress()
                    }
                    .onChange(of: timerService.liveProgress) { _, newProgress in
                        updateOptimisticProgress()
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
    
    // MARK: - Content Views
    
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
                currentProgress: .constant(displayProgress),
                completionPercentage: displayCompletionPercentage,
                formattedProgress: displayFormattedProgress,
                onIncrement: { incrementProgressOptimistically() },
                onDecrement: { decrementProgressOptimistically() }
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
        .overlay {
            if viewModel.isTimeInputPresented {
                // Фон с анимацией
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.isTimeInputPresented = false
                    }
                    .transition(.opacity)
            }
        }
        .overlay {
            if viewModel.isTimeInputPresented {
                // Карточка с усиленной анимацией
                TimeInputView(
                    habit: habit,
                    isPresented: Binding(
                        get: { viewModel.isTimeInputPresented },
                        set: { viewModel.isTimeInputPresented = $0 }
                    ),
                    onConfirm: { hours, minutes in
                        viewModel.handleCustomTimeInput(hours: hours, minutes: minutes)
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.7).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(duration: 0.6, bounce: 0.3), value: viewModel.isTimeInputPresented)
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
            onCountInput: { viewModel.handleCountInput() },
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
                if let onDelete = onDelete {
                    onDelete()
                } else {
                    dismiss()
                }
            },
            habit: habit
        )
    }
    
    // MARK: - ✅ НОВЫЕ МЕТОДЫ: Optimistic UI Updates
    
    /// ✅ Синхронизация optimistic progress с реальными данными
        @MainActor
        private func syncOptimisticProgress() async {
            guard let viewModel = viewModel else { return }
            
            let actualProgress = viewModel.currentProgress
            
            // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: НЕ синхронизируем для активных таймеров
            if habit.type == .time && Calendar.current.isDateInToday(date) && viewModel.isTimerRunning {
                print("🔄 Skipping sync for active timer")
                return
            }
            
            // Обновляем optimistic progress только если есть расхождение
            if optimisticProgress != actualProgress {
                print("🔄 Syncing optimistic progress: \(optimisticProgress) -> \(actualProgress)")
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    optimisticProgress = actualProgress
                }
            }
        }
    
    private func updateOptimisticProgress() {
        guard let viewModel = viewModel else { return }
        
        let newProgress = viewModel.currentProgress
        
        // ✅ ПРОСТОЕ условие: обновляем если изменилось
        if optimisticProgress != newProgress {
            optimisticProgress = newProgress
        }
    }
    
    private func incrementProgressOptimistically() {
        guard !isAlreadyCompleted else {
            HapticManager.shared.play(.error)
            return
        }
        
        // 1. ✅ МГНОВЕННОЕ обновление UI
        let incrementValue = habit.type == .count ? 1 : 60
        optimisticProgress = min(optimisticProgress + incrementValue, 999999)
        
        // 2. ✅ МГНОВЕННЫЙ хаптик
        HapticManager.shared.playSelection()
        
        // 3. ✅ ПРОСТОЕ фоновое сохранение
        Task {
            await performBackgroundIncrement()
        }
    }

    /// ✅ ПРОСТОЕ уменьшение БЕЗ сложной логики
    private func decrementProgressOptimistically() {
        guard optimisticProgress > 0 else { return }
        
        // 1. ✅ МГНОВЕННОЕ обновление UI
        let decrementValue = habit.type == .count ? 1 : 60
        optimisticProgress = max(optimisticProgress - decrementValue, 0)
        
        // 2. ✅ МГНОВЕННЫЙ хаптик
        HapticManager.shared.playSelection()
        
        // 3. ✅ ПРОСТОЕ фоновое сохранение
        Task {
            await performBackgroundDecrement()
        }
    }
    
    @MainActor
    private func performBackgroundIncrement() async {
        guard let viewModel = viewModel else { return }
        
        do {
            try await viewModel.incrementProgressAsync()
            
            // ✅ ПРОСТАЯ синхронизация
            let actualProgress = viewModel.currentProgress
            if optimisticProgress != actualProgress {
                withAnimation(.easeInOut(duration: 0.1)) {
                    optimisticProgress = actualProgress
                }
            }
        } catch {
            print("❌ Increment failed: \(error)")
            // Откат при ошибке
            let rollback = habit.type == .count ? 1 : 60
            optimisticProgress = max(optimisticProgress - rollback, 0)
            HapticManager.shared.play(.error)
        }
    }
    
    @MainActor
    private func performBackgroundDecrement() async {
        guard let viewModel = viewModel else { return }
        
        do {
            try await viewModel.decrementProgressAsync()
            
            // ✅ ПРОСТАЯ синхронизация
            let actualProgress = viewModel.currentProgress
            if optimisticProgress != actualProgress {
                withAnimation(.easeInOut(duration: 0.1)) {
                    optimisticProgress = actualProgress
                }
            }
        } catch {
            print("❌ Decrement failed: \(error)")
            // Откат при ошибке
            let rollback = habit.type == .count ? 1 : 60
            optimisticProgress = min(optimisticProgress + rollback, 999999)
            HapticManager.shared.play(.error)
        }
    }
    
    // MARK: - Helper Properties
    
    private var isAlreadyCompleted: Bool {
        displayProgress >= habit.goal
    }
    
    // MARK: - Setup Methods
    
    private func setupViewModel(with newDate: Date? = nil) {
        viewModel?.cleanup()
        
        let vm = HabitDetailViewModel(
            habit: habit,
            date: newDate ?? date,
            modelContext: modelContext
        )
        vm.onHabitDeleted = onDelete
        viewModel = vm
        
        // ✅ Простая инициализация
        optimisticProgress = vm.currentProgress
    }
    
    // MARK: - Остальные методы остаются без изменений...
    
    private func goalInfoView(viewModel: HabitDetailViewModel) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if let iconName = habit.iconName {
                    Image(systemName: iconName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text("goal".localized(with: viewModel.formattedGoal))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 8)
    }
    
    private func actionButtonsView(viewModel: HabitDetailViewModel) -> some View {
        ActionButtonsSection(
            habit: habit,
            date: date,
            isTimerRunning: viewModel.isTimerRunning,
            onReset: {
                optimisticProgress = 0
                HapticManager.shared.play(.error)
                Task {
                    do {
                        try await viewModel.resetProgressAsync()
                        await syncOptimisticProgress()
                    } catch {
                        print("❌ Reset failed: \(error)")
                        // В случае ошибки восстанавливаем данные
                        await syncOptimisticProgress()
                    }
                }
            },
            onTimerToggle: {
                viewModel.toggleTimer()
            },
            onManualEntry: {
                if habit.type == .time {
                    viewModel.isTimeInputPresented = true
                } else {
                    viewModel.alertState.isCountAlertPresented = true
                }
            }
        )
    }
    
    private func completeButtonView(viewModel: HabitDetailViewModel) -> some View {
        Button(action: {
            // ✅ Мгновенно обновляем optimistic progress до goal
            optimisticProgress = habit.goal
            HapticManager.shared.play(.success)
            
            // ✅ Асинхронно сохраняем в фоне
            Task {
                do {
                    try await viewModel.completeHabitAsync()
                    await syncOptimisticProgress()
                } catch {
                    print("❌ Complete failed: \(error)")
                    // В случае ошибки возвращаем предыдущее значение
                    await syncOptimisticProgress()
                    HapticManager.shared.play(.error)
                }
            }
        }) {
            Text(isAlreadyCompleted ? "completed".localized : "complete".localized)
        }
        .beautifulButton(
            habit: habit,
            isEnabled: !isAlreadyCompleted,
            lightOpacity: 0.8,
            darkOpacity: 1.0
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }
    
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
        
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    isEditPresented = true
                } label: {
                    Label("button_edit".localized, systemImage: "pencil")
                }
                .withHabitTint(habit)
                
                Button {
                    archiveHabit()
                } label: {
                    Label("archive".localized, systemImage: "archivebox")
                }
                .withHabitTint(habit)
                
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
