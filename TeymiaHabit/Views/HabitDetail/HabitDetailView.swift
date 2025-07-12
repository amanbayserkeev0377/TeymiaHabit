import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    let date: Date
    
    @State private var viewModel: HabitDetailViewModel?
    @State private var isEditPresented = false
    @State private var navigateToStatistics = false
    
    @State private var inputManager = InputOverlayManager()
    
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    // Main content
                    if let viewModel = viewModel {
                        VStack(spacing: 0) {
                            // Progress and actions
                            progressAndActionsContent(viewModel: viewModel)
                            
                            // Bottom button
                            completeButtonView(viewModel: viewModel)
                        }
                    }
                }
                .padding(.top, 16)
            }
            .navigationTitle(habit.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigateToStatistics = true
                    } label: {
                        Image(systemName: "chart.line.text.clipboard")
                            .font(.system(size: 14))
                            .foregroundStyle(habit.iconColor.color)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(habit.iconColor.adaptiveGradient(for: colorScheme).opacity(0.2))
                            )
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(habit.iconColor.color)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(habit.iconColor.adaptiveGradient(for: colorScheme).opacity(0.2))
                            )
                    }
                }
            }
        .id(habit.uuid.uuidString)
        .onAppear {
            setupViewModelIfNeeded()
        }
        .onDisappear {
            HabitManager.shared.cleanupInactiveViewModels()
        }
        .onChange(of: habit.uuid) { _, _ in
            setupViewModelIfNeeded()
        }
        .onChange(of: date) { _, newDate in
            viewModel?.updateDisplayedDate(newDate)
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
        .sheet(isPresented: $isEditPresented) {
            NewHabitView(habit: habit)
        }
        .navigationDestination(isPresented: $navigateToStatistics) {
            HabitStatisticsView(habit: habit)
        }
        .deleteSingleHabitAlert(
            isPresented: Binding(
                get: { viewModel?.alertState.isDeleteAlertPresented ?? false },
                set: { viewModel?.alertState.isDeleteAlertPresented = $0 }
            ),
            habitName: habit.title,
            onDelete: {
                viewModel?.deleteHabit()
                dismiss()
            },
            habit: habit
        )
        .inputOverlay(
            habit: habit,
            inputType: inputManager.activeInputType,
            onCountInput: { count in
                viewModel?.handleCustomCountInput(count: count)
            },
            onTimeInput: { hours, minutes in
                viewModel?.handleCustomTimeInput(hours: hours, minutes: minutes)
            },
            onDismiss: {
                inputManager.dismiss()
            }
        )
    }
    
    // MARK: - Progress and Actions
    @ViewBuilder
    private func progressAndActionsContent(viewModel: HabitDetailViewModel) -> some View {
        VStack(spacing: 24) {
            // Goal info
            HStack(spacing: 8) {
                universalIcon(
                    iconId: habit.iconName,
                    baseSize: 22,
                    color: habit.iconColor,
                    colorScheme: colorScheme
                )
                
                Text("goal".localized(with: viewModel.formattedGoal))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            
            // Progress control
            ProgressControlSection(
                habit: habit,
                currentProgress: .constant(viewModel.currentProgress),
                completionPercentage: viewModel.completionPercentage,
                formattedProgress: getFormattedProgress(viewModel: viewModel),
                onIncrement: {
                    viewModel.incrementProgress()
                },
                onDecrement: {
                    viewModel.decrementProgress()
                }
            )
            
            // Action buttons
            HStack(spacing: 16) {
                ActionButtonsSection(
                    habit: habit,
                    date: date,
                    isTimerRunning: viewModel.isTimerRunning,
                    onReset: {
                        viewModel.resetProgress()
                    },
                    onTimerToggle: {
                        viewModel.toggleTimer()
                    },
                    onManualEntry: {
                        if habit.type == .time {
                            inputManager.showTimeInput()
                        } else {
                            inputManager.showCountInput()
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Complete Button
    private func completeButtonView(viewModel: HabitDetailViewModel) -> some View {
        Button(action: {
            viewModel.completeHabit()
        }) {
            Text(viewModel.isAlreadyCompleted ? "completed".localized : "complete".localized)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(viewModel.isAlreadyCompleted ? Color.secondary : Color.white)
                .frame(maxWidth: min(340, UIScreen.main.bounds.width * 0.85))
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            viewModel.isAlreadyCompleted
                            ? AnyShapeStyle(LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(habit.iconColor.adaptiveGradient(for: colorScheme).opacity(0.9))
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isAlreadyCompleted)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isAlreadyCompleted)
        .scaleEffect(viewModel.isAlreadyCompleted ? 0.98 : 1.0)
        .modifier(HapticManager.shared.sensoryFeedback(.impact(weight: .medium), trigger: !viewModel.isAlreadyCompleted))
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    // MARK: - Helper Methods
    private func getFormattedProgress(viewModel: HabitDetailViewModel) -> String {
        let currentProgressValue = viewModel.currentProgress
        
        switch habit.type {
        case .count:
            return currentProgressValue.formattedAsProgress(total: habit.goal)
        case .time:
            return currentProgressValue.formattedAsTime()
        }
    }
    
    private func setupViewModelIfNeeded() {
        if let existingViewModel = viewModel,
           existingViewModel.habitId == habit.uuid.uuidString {
            existingViewModel.updateDisplayedDate(date)
            return
        }
        
        let vm = try! HabitManager.shared.getViewModel(for: habit, date: date, modelContext: modelContext)
        vm.onHabitDeleted = {
            dismiss()
        }
        viewModel = vm
    }
    
    private func archiveHabit() {
        habit.isArchived = true
        try? modelContext.save()
        HapticManager.shared.play(.success)
        dismiss()
    }
}
