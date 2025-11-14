import SwiftUI
import SwiftData
import AVFoundation

struct HabitDetailView: View {
    let habit: Habit
    let date: Date
    
    @State private var viewModel: HabitDetailViewModel?
    @State private var isEditPresented = false
    @State private var inputManager = InputOverlayManager()
    @State private var showingStatistics = false
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            if let viewModel = viewModel {
                habitDetailViewContent(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingStatistics = true
                } label: {
                    Image("stats.fill")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .tint(.primary)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isEditPresented = true
                    } label: {
                        Label("button_edit".localized, image: "pencil")
                    }
                    .tint(.primary)
                    
                    Button {
                        archiveHabit()
                    } label: {
                        Label("archive".localized, image: "archive")
                    }
                    .tint(.primary)
                    
                    Button(role: .destructive) {
                        viewModel?.alertState.isDeleteAlertPresented = true
                        
                    } label: {
                        Label("button_delete".localized, image: "trash.small")
                        
                    }
                    .tint(.red)
                } label: {
                    Image(systemName: "ellipsis")
                }
                .tint(.primary)
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
        .sheet(isPresented: $showingStatistics) {
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
    
    // MARK: - Content
    
    @ViewBuilder
    private func habitDetailViewContent(viewModel: HabitDetailViewModel) -> some View {
        VStack(spacing: 30) {
            topSectionView()
            
            progressRingSection(viewModel: viewModel)
            
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
            
            completeButtonView(viewModel: viewModel)
            
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func topSectionView() -> some View {
        VStack {
            Text(habit.title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 24)
            
            Text("goal".localized(with: habit.formattedGoal))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    
    
    @ViewBuilder
    private func progressRingSection(viewModel: HabitDetailViewModel) -> some View {
        HStack(spacing: 0) {
            Spacer()
            Button {
                HapticManager.shared.playSelection()
                viewModel.decrementProgress()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.primary.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentProgress <= 0)
            
            Spacer()
            
            ProgressRing.detail(
                progress: viewModel.completionPercentage,
                currentProgress: viewModel.currentProgress,
                goal: habit.goal,
                habitType: habit.type,
                isCompleted: viewModel.isAlreadyCompleted,
                isExceeded: viewModel.currentProgress > habit.goal,
                habit: habit,
                size: 170,
                lineWidth: 16,
                fontSize: 32
            )
            
            Spacer()
            
            Button {
                HapticManager.shared.playSelection()
                viewModel.incrementProgress()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.primary.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    private func completeButtonView(viewModel: HabitDetailViewModel) -> some View {
        Button(action: {
            if !viewModel.isAlreadyCompleted {
                HapticManager.shared.playImpact(.medium)
            }
            viewModel.completeHabit()
        }) {
            Text(viewModel.isAlreadyCompleted ? "completed".localized : "complete".localized)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(viewModel.isAlreadyCompleted ? Color.secondary : Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            viewModel.isAlreadyCompleted
                            ? AnyShapeStyle(LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(habit.iconColor.color.gradient.opacity(0.9))
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isAlreadyCompleted)
        .scaleEffect(viewModel.isAlreadyCompleted ? 0.97 : 1.0)
        .animation(.smooth(duration: 1.0), value: viewModel.isAlreadyCompleted)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Helper Methods
    
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
