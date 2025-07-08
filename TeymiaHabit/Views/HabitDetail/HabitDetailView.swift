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
                dragOffset = max(0, value.translation.height) // ✅ height вместо y
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

// MARK: - Content View (без navigation)

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
    
    @State private var localProgress: Int = 0
    @State private var localCompletionPercentage: Double = 0
    @State private var localFormattedProgress: String = ""
    @State private var localIsCompleted: Bool = false
    
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
            setupViewModel()
        }
        .onDisappear {
            viewModel?.saveIfNeeded()
            viewModel?.cleanup()
        }
        .onChange(of: viewModel?.localUpdateTrigger) { _, _ in
                    updateLocalProgress()
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
    
    private func setupViewModel() {
            let vm = HabitDetailViewModel(
                habit: habit,
                date: date,
                modelContext: modelContext
            )
            vm.onHabitDeleted = onDelete
            viewModel = vm
            
            // ✅ Инициализируем локальные значения
            updateLocalProgress()
        }
        
        // ✅ НОВЫЙ метод для обновления локального состояния
        private func updateLocalProgress() {
            guard let viewModel = viewModel else { return }
            
            localProgress = viewModel.currentProgress
            localCompletionPercentage = habit.goal > 0 ? Double(localProgress) / Double(habit.goal) : 0
            localFormattedProgress = habit.formattedProgress(for: date, currentProgress: localProgress)
            localIsCompleted = localProgress >= habit.goal
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
                // Progress control с кнопками +/-
                ProgressControlSection(
                    habit: habit,
                    currentProgress: .constant(localProgress),
                    completionPercentage: localCompletionPercentage,
                    formattedProgress: localFormattedProgress,
                    onIncrement: {
                        viewModel.incrementProgress()
                        updateLocalProgress()
                    },
                    onDecrement: {
                        viewModel.decrementProgress()
                        updateLocalProgress()
                    }
                )
                
                // Action buttons + right buttons
                HStack(spacing: 16) {
                    ActionButtonsSection(
                        habit: habit,
                        date: date,
                        isTimerRunning: viewModel.isTimerRunning,
                        onReset: {
                            viewModel.resetProgress()
                            updateLocalProgress()
                        },
                        onTimerToggle: {
                            viewModel.toggleTimer()
                        },
                        onManualEntry: {
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
    
    @ViewBuilder
    private func bottomButtonContent(viewModel: HabitDetailViewModel) -> some View {
        Button(action: {
            viewModel.completeHabit()
            updateLocalProgress()
        }) {
            Text(localIsCompleted ? "completed".localized : "complete".localized)
        }
        .beautifulButton(
            habit: habit,
            isEnabled: !localIsCompleted,
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
                        updateLocalProgress()
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
                        updateLocalProgress()
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
