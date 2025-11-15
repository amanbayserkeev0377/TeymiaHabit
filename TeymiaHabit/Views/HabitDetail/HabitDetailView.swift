import SwiftUI
import SwiftData
import AVFoundation

struct HabitDetailView: View {
    let habit: Habit
    let date: Date
    
    @State private var viewModel: HabitDetailViewModel?
    @State private var isEditPresented = false
    @State private var showingStatistics = false
    @State private var showingCountInput = false
    @State private var showingTimeInput = false
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        contentView
            .popover(
                isPresented: $showingCountInput,
                attachmentAnchor: PopoverAttachmentAnchor.point(.bottom),
                arrowEdge: .bottom
            ) {
                countInputPopover
            }
            .popover(
                isPresented: $showingTimeInput,
                attachmentAnchor: PopoverAttachmentAnchor.point(.center),
                arrowEdge: .bottom
            ) {
                timeInputPopover
            }
            .toolbar { toolbarContent }
            .sheet(isPresented: $isEditPresented) {
                NewHabitView(habit: habit)
            }
            .sheet(isPresented: $showingStatistics) {
                HabitStatisticsView(habit: habit)
            }
            .deleteSingleHabitAlert(
                isPresented: deleteAlertBinding,
                habitName: habit.title,
                onDelete: deleteHabit,
                habit: habit
            )
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
    }
    
    // MARK: - Content Views
    
    private var contentView: some View {
        VStack(spacing: 0) {
            if let viewModel = viewModel {
                habitDetailViewContent(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var countInputPopover: some View {
        CountInputPopover(habit: habit) { count in
            viewModel?.handleCustomCountInput(count: count)
        }
    }
    
    private var timeInputPopover: some View {
        TimeInputPopover(habit: habit) { hours, minutes in
            viewModel?.handleCustomTimeInput(hours: hours, minutes: minutes)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            statsButton
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            menuButton
        }
    }
    
    private var statsButton: some View {
        Button {
            showingStatistics = true
        } label: {
            Image("stats.fill")
                .resizable()
                .frame(width: 16, height: 16)
        }
        .tint(.primary)
    }
    
    private var menuButton: some View {
        Menu {
            editButton
            archiveButton
            deleteButton
        } label: {
            Image(systemName: "ellipsis")
        }
        .tint(.primary)
    }
    
    private var editButton: some View {
        Button {
            isEditPresented = true
        } label: {
            Label("button_edit".localized, image: "pencil")
        }
        .tint(.primary)
    }
    
    private var archiveButton: some View {
        Button {
            archiveHabit()
        } label: {
            Label("archive".localized, image: "archive")
        }
        .tint(.primary)
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            viewModel?.alertState.isDeleteAlertPresented = true
        } label: {
            Label("button_delete".localized, image: "trash.small")
        }
        .tint(.red)
    }
    
    // MARK: - Bindings
    
    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.alertState.isDeleteAlertPresented ?? false },
            set: { viewModel?.alertState.isDeleteAlertPresented = $0 }
        )
    }
    
    // MARK: - Content Sections
    
    @ViewBuilder
    private func habitDetailViewContent(viewModel: HabitDetailViewModel) -> some View {
        VStack(spacing: 30) {
            topSectionView()
            progressRingSection(viewModel: viewModel)
            actionButtonsSection(viewModel: viewModel)
            completeButtonView(viewModel: viewModel)
        }
    }
    
    @ViewBuilder
    private func topSectionView() -> some View {
        VStack {
            Text(habit.title)
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 24)
            
            Text("goal".localized(with: habit.formattedGoal))
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func progressRingSection(viewModel: HabitDetailViewModel) -> some View {
        HStack(spacing: 0) {
            Spacer()
            decrementButton(viewModel: viewModel)
            Spacer()
            progressRing(viewModel: viewModel)
            Spacer()
            incrementButton(viewModel: viewModel)
            Spacer()
        }
    }
    
    private func decrementButton(viewModel: HabitDetailViewModel) -> some View {
        Button {
            HapticManager.shared.playSelection()
            viewModel.decrementProgress()
        } label: {
            Image(systemName: "minus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.secondary.opacity(0.1)))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.currentProgress <= 0)
    }
    
    private func progressRing(viewModel: HabitDetailViewModel) -> some View {
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
    }
    
    private func incrementButton(viewModel: HabitDetailViewModel) -> some View {
        Button {
            HapticManager.shared.playSelection()
            viewModel.incrementProgress()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.secondary.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }
    
    private func actionButtonsSection(viewModel: HabitDetailViewModel) -> some View {
        ActionButtonsSection(
            habit: habit,
            date: date,
            isTimerRunning: viewModel.isTimerRunning,
            onReset: { viewModel.resetProgress() },
            onTimerToggle: { viewModel.toggleTimer() },
            onManualEntry: {
                if habit.type == .time {
                    showingTimeInput = true
                } else {
                    showingCountInput = true
                }
            }
        )
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
                .foregroundStyle(viewModel.isAlreadyCompleted ? Color.secondary : textColorForButton)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            viewModel.isAlreadyCompleted
                            ? AnyShapeStyle(LinearGradient(
                                colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
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
        vm.onHabitDeleted = { dismiss() }
        viewModel = vm
    }
    
    private func archiveHabit() {
        habit.isArchived = true
        try? modelContext.save()
        HapticManager.shared.play(.success)
        dismiss()
    }
    
    private func deleteHabit() {
        viewModel?.deleteHabit()
        dismiss()
    }
    
    private var textColorForButton: Color {
        if habit.iconColor == .primary {
            return Color(uiColor: .systemBackground)
        }
        return .white
    }
}
