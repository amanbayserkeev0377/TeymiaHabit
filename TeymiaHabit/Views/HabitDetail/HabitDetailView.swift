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
    @State private var confettiTrigger = 0
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isCompactDevice: Bool {
        UIDevice.current.userInterfaceIdiom == .pad ||
        UIScreen.main.bounds.height <= 667
    }
    
    private var adaptiveSpacing: (small: CGFloat, medium: CGFloat, large: CGFloat) {
        if isCompactDevice {
            return (10, 18, 24)
        } else {
            return (14, 24, 36)
        }
    }
    
    private var adaptiveProgressRingSize: CGFloat {
        if isCompactDevice { return 170 }
        else { return 200 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let viewModel = viewModel {
                    habitDetailViewContent(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text(formattedDateForToolbar())
                    .foregroundStyle(.secondary)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingStatistics = true
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 14))
                        .withHabitGradient(habit, colorScheme: colorScheme)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(
                                    habit.iconColor.color.opacity(0.1)
                                )
                        )
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
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
                        .font(.system(size: 16))
                        .withHabitGradient(habit, colorScheme: colorScheme)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(
                                    habit.iconColor.color.opacity(0.1)
                                )
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
        .onChange(of: viewModel?.isAlreadyCompleted) { oldValue, newValue in
            if oldValue == false && newValue == true {
                confettiTrigger += 1
            }
        }
        .sheet(isPresented: $isEditPresented) {
            NewHabitView(habit: habit)
        }
        .sheet(isPresented: $showingStatistics) {
            HabitStatisticsView(habit: habit)
                .presentationSizing(.page)
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
        .confettiCannon(
            trigger: $confettiTrigger,
            num: 50,
            confettis: [.shape(.circle), .shape(.triangle), .shape(.square)],
            colors: [.orange, .green, .blue, .red, .yellow, .purple, .pink, .cyan],
            confettiSize: 12.0,
            rainHeight: 800.0,
            radius: 400,
            hapticFeedback: false
        )
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private func habitDetailViewContent(viewModel: HabitDetailViewModel) -> some View {
        VStack(spacing: 0) {
            topSectionView()
            
            Spacer().frame(height: adaptiveSpacing.medium)
            
            DayStreaksView(habit: habit, date: date)
                .padding(.horizontal, 24)
            
            Spacer().frame(height: adaptiveSpacing.large)

            progressRingSection(viewModel: viewModel)
            
            Spacer().frame(height: adaptiveSpacing.large)

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
            
            Spacer().frame(height: adaptiveSpacing.large)

            completeButtonView(viewModel: viewModel)
            
            Spacer().frame(height: adaptiveSpacing.medium)
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func topSectionView() -> some View {
        VStack(spacing: adaptiveSpacing.medium) {
            universalIcon(
                iconId: habit.iconName,
                baseSize: isCompactDevice ? 32 : 36,
                color: habit.iconColor,
                colorScheme: colorScheme
            )
            
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
        .padding(.top, 8)
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
                    .withHabitGradient(habit, colorScheme: colorScheme)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                habit.iconColor.color.opacity(0.1)
                            )
                    )
            }
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
                size: adaptiveProgressRingSize,
                lineWidth: 16,
                fontSize: isCompactDevice ? 28 : 32
            )
            
            Spacer()
            
            Button {
                HapticManager.shared.playSelection()
                viewModel.incrementProgress()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .withHabitGradient(habit, colorScheme: colorScheme)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                habit.iconColor.color.opacity(0.1)
                            )
                    )
            }
            
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
                .frame(height: isCompactDevice ? 48 : 52)
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
    
    private func formattedDateForToolbar() -> String {
        if Calendar.current.isDateInToday(date) {
            return "today".localized.capitalized
        } else if Calendar.current.isDateInYesterday(date) {
            return "yesterday".localized.capitalized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, d MMM"
            return formatter.string(from: date).capitalized
        }
    }
}
