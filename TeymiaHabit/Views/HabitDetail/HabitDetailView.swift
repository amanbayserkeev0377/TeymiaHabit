import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    let date: Date
    @Binding var isPresented: Bool
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    var body: some View {
        ZStack {
            // Main content card
            VStack(spacing: 0) {
                // Handle bar for drag gesture
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                // HabitDetailView content (убираем navigation stuff)
                HabitDetailContentView(
                    habit: habit,
                    date: date,
                    onDelete: {
                        dismissWithAnimation()
                    },
                    onDismiss: {
                        dismissWithAnimation()
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color(.separator).opacity(0.6), lineWidth: 0.7)
                    )
                    .shadow(
                        color: Color.primary.opacity(0.2),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
            .padding(.horizontal, 12)
            .padding(.top, 100)
            .offset(y: dragOffset)
            .gesture(dragGesture)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: dragOffset)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .move(edge: .bottom))
        ))
        .zIndex(1000) // Поверх всего
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                // Только drag вниз разрешен
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                isDragging = false
                
                let dismissThreshold: CGFloat = 120
                let velocityThreshold: CGFloat = 800
                
                // Dismiss если drag больше порога или быстрый swipe вниз
                if value.translation.height > dismissThreshold || value.velocity.height > velocityThreshold {
                    dismissWithAnimation()
                } else {
                    // Возвращаем в исходное положение
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }
    
    // MARK: - Actions
    
    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            dragOffset = UIScreen.main.bounds.height // Slide down off screen
        }
        
        // Delay для завершения анимации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            dragOffset = 0 // Reset для следующего показа
        }
    }
}

// MARK: - Content View (БЕЗ локального состояния!)

struct HabitDetailContentView: View {
    let habit: Habit
    let date: Date
    let onDelete: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var viewModel: HabitDetailViewModel?
    @State private var isEditPresented = false
    @State private var showStatistics = false
    @State private var errorMessage: String?
    
    private var stableViewID: String {
        return habit.uuid.uuidString
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let viewModel = viewModel {
                // Header с кнопкой закрытия
                headerContent(viewModel: viewModel)
                
                // Progress and actions (копируем структуру)
                progressAndActionsContent(viewModel: viewModel)
                
                // Bottom button
                bottomButtonContent(viewModel: viewModel)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            debugPrint("🎨 HabitDetailContentView onAppear for: \(habit.title)")
            setupViewModelIfNeeded()
        }
        .onDisappear {
            debugPrint("🎨 HabitDetailContentView onDisappear for: \(habit.title)")
            HabitManager.shared.cleanupInactiveViewModels()
        }
        .id(stableViewID) // ✅ Стабильный ID
        .onChange(of: habit.uuid) { _, newUUID in
            debugPrint("🔄 Habit UUID changed to: \(newUUID)")
            // ✅ При смене привычки - пересоздаем ViewModel
            setupViewModelIfNeeded()
        }
        .onChange(of: date) { _, newDate in
            debugPrint("🔄 Date changed to: \(newDate)")
            viewModel?.updateDisplayedDate(newDate)
        }
        .sheet(isPresented: $isEditPresented) {
            NewHabitView(habit: habit)
        }
        .sheet(isPresented: $showStatistics) {
            HabitStatisticsView(habit: habit)
        }
        .onChange(of: viewModel?.alertState.successFeedbackTrigger) { _, newValue in
            if let newValue = newValue, newValue {
                HapticManager.shared.play(.success)
            }
        }
        .onChange(of: viewModel?.alertState.errorFeedbackTrigger) { _, newValue in
            if let newValue = newValue, newValue {
                HapticManager.shared.play(.error)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel?.isCountInputPresented)
        .animation(.easeInOut(duration: 0.25), value: viewModel?.isTimeInputPresented)
        .deleteSingleHabitAlert(
            isPresented: Binding(
                get: { viewModel?.alertState.isDeleteAlertPresented ?? false },
                set: { viewModel?.alertState.isDeleteAlertPresented = $0 }
            ),
            habitName: habit.title,
            onDelete: {
                viewModel?.deleteHabit()
                onDelete()
            },
            habit: habit
        )
        .overlay(alignment: .center) {
            overlayContent()
        }
    }
    
    // MARK: - Setup & Components
    
    private func setupViewModelIfNeeded() {
        // ✅ Проверяем, есть ли уже правильный ViewModel для этой привычки
        if let existingViewModel = viewModel,
           existingViewModel.habitId == habit.uuid.uuidString {
            debugPrint("✅ Correct ViewModel already exists for: \(habit.title)")
            existingViewModel.updateDisplayedDate(date)
            return
        }
        
        debugPrint("🔧 Getting ViewModel from HabitManager for: \(habit.title)")
        
        do {
            let vm = try HabitManager.shared.getViewModel(for: habit, date: date, modelContext: modelContext)
            vm.onHabitDeleted = onDelete
            viewModel = vm
            errorMessage = nil
            debugPrint("✅ ViewModel obtained from HabitManager")
        } catch {
            debugPrint("❌ Error getting ViewModel: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    @ViewBuilder
    private func headerContent(viewModel: HabitDetailViewModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    showStatistics = true
                } label: {
                    Image(systemName: "chart.line.text.clipboard")
                        .font(.system(size: 18))
                        .foregroundStyle(habit.iconColor.color)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(habit.iconColor.adaptiveGradient(for: colorScheme)
                                    .opacity(0.1))
                        )
                }
                // Menu button
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
                        viewModel.alertState.isDeleteAlertPresented = true
                    } label: {
                        Label("button_delete".localized, systemImage: "trash")
                    }
                    .tint(.red)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundStyle(habit.iconColor.color)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(habit.iconColor.adaptiveGradient(for: colorScheme)
                                    .opacity(0.1))
                        )
                }
            }
            .padding(.top)
            .padding(.trailing)
            
            // Заголовок
            Text(habit.title)
                .font(.largeTitle.bold())
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            // Goal info
            HStack(spacing: 8) {
                if let iconName = habit.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 22))
                        .foregroundStyle(habit.iconColor.adaptiveGradient(for: colorScheme))
                }
                
                Text("goal".localized(with: viewModel.formattedGoal))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func progressAndActionsContent(viewModel: HabitDetailViewModel) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // ✅ Progress control с кнопками +/- - используем ТОЛЬКО ViewModel
                ProgressControlSection(
                    habit: habit,
                    currentProgress: .constant(viewModel.currentProgress),
                    completionPercentage: viewModel.completionPercentage,
                    formattedProgress: getFormattedProgress(viewModel: viewModel), // ← Вызываем отдельную функцию
                    onIncrement: {
                        debugPrint("🔧 UI: increment button pressed for \(habit.title)")
                        viewModel.incrementProgress()
                    },
                    onDecrement: {
                        debugPrint("🔧 UI: decrement button pressed for \(habit.title)")
                        viewModel.decrementProgress()
                    }
                )
                .onChange(of: viewModel.currentProgress) { _, newValue in
                    // ✅ Отладка при изменении прогресса
                    debugPrint("🔄 Progress changed for \(habit.title): \(newValue)")
                }
                
                // Action buttons + right buttons
                HStack(spacing: 16) {
                    ActionButtonsSection(
                        habit: habit,
                        date: date,
                        isTimerRunning: viewModel.isTimerRunning,
                        onReset: {
                            debugPrint("🔧 UI: reset button pressed for \(habit.title)")
                            viewModel.resetProgress()
                        },
                        onTimerToggle: {
                            debugPrint("🔧 UI: timer toggle pressed for \(habit.title)")
                            viewModel.toggleTimer()
                        },
                        onManualEntry: {
                            debugPrint("🔧 UI: manual entry pressed for \(habit.title)")
                            if habit.type == .time {
                                viewModel.isTimeInputPresented = true
                            } else {
                                viewModel.isCountInputPresented = true
                            }
                        }
                    )
                }
            }
            Spacer()
        }
    }
    
    // ✅ НОВАЯ вспомогательная функция для форматирования прогресса
    private func getFormattedProgress(viewModel: HabitDetailViewModel) -> String {
        let currentProgressValue = viewModel.currentProgress
        
        let formattedValue: String
        switch habit.type {
        case .count:
            formattedValue = currentProgressValue.formattedAsProgress(total: habit.goal)
        case .time:
            formattedValue = currentProgressValue.formattedAsTime()
        }
        
        return formattedValue
    }
    
    @ViewBuilder
    private func bottomButtonContent(viewModel: HabitDetailViewModel) -> some View {
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
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func overlayContent() -> some View {
        ZStack {
            // Count Input Overlay
            if viewModel?.isCountInputPresented == true {
                CountInputView(
                    habit: habit,
                    isPresented: Binding(
                        get: { viewModel?.isCountInputPresented ?? false },
                        set: { viewModel?.isCountInputPresented = $0 }
                    ),
                    onConfirm: { count in
                        viewModel?.handleCustomCountInput(count: count)
                        // ✅ УБИРАЕМ updateLocalProgress() - не нужен
                    }
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(999)
            }
            
            // Time Input Overlay
            if viewModel?.isTimeInputPresented == true {
                TimeInputView(
                    habit: habit,
                    isPresented: Binding(
                        get: { viewModel?.isTimeInputPresented ?? false },
                        set: { viewModel?.isTimeInputPresented = $0 }
                    ),
                    onConfirm: { hours, minutes in
                        viewModel?.handleCustomTimeInput(hours: hours, minutes: minutes)
                        // ✅ УБИРАЕМ updateLocalProgress() - не нужен
                    }
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(999)
            }
        }
    }
    
    private func archiveHabit() {
        habit.isArchived = true
        try? modelContext.save()
        HapticManager.shared.play(.success)
        onDelete()
    }
}
