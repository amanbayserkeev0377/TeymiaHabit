import SwiftUI
import SwiftData
import AVFoundation

struct HabitDetailView: View {
    let habit: Habit
    let date: Date
    
    @State private var viewModel: HabitDetailViewModel?
    @State private var isEditPresented = false
    @State private var showingStatistics = false
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                if let viewModel = viewModel {
                    progressRingSection(viewModel: viewModel)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(habit.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("goal".localized(with: habit.formattedGoal))
                        .font(.callout)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingStatistics = true
                    } label: {
                        Image("stats.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .withHabitGradient(habit, colorScheme: colorScheme)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isEditPresented = true
                        } label: {
                            Label("button_edit".localized, image: "pencil.small")
                        }
                        .withHabitTint(habit)
                        
                        Button {
                            archiveHabit()
                        } label: {
                            Label("archive".localized, image: "archive")
                        }
                        .withHabitTint(habit)
                        
                        Button(role: .destructive) {
                            viewModel?.alertState.isDeleteAlertPresented = true
                        } label: {
                            Label("button_delete".localized, image: "trash.small")
                        }
                        .tint(.red)
                    } label: {
                        Image(systemName: "ellipsis")
                            .withHabitGradient(habit, colorScheme: colorScheme)
                    }
                }
            }
            .onAppear {
                setupViewModelIfNeeded()
            }
            .onDisappear {
                HabitManager.shared.cleanupInactiveViewModels()
            }
            .onChange(of: date) { _, newDate in
                viewModel?.updateDisplayedDate(newDate)
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
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func progressRingSection(viewModel: HabitDetailViewModel) -> some View {
        Section {
            VStack(spacing: 16) {
                ProgressRing.detail(
                    progress: viewModel.completionPercentage,
                    currentProgress: viewModel.currentProgress,
                    goal: habit.goal,
                    habitType: habit.type,
                    isCompleted: viewModel.isAlreadyCompleted,
                    isExceeded: viewModel.currentProgress > habit.goal,
                    habit: habit,
                    size: 180,
                    lineWidth: 16,
                    fontSize: 30
                )
                .padding(.bottom, 3)
                
                stepperRow(viewModel: viewModel)
                // Slider (only if goal > 1)
                if habit.goal > 1 {
                    sliderRow(viewModel: viewModel)
                }
                
                completeButtonView(viewModel: viewModel)
                
            }
            .frame(maxWidth: .infinity)
        }
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Row Components
    
    @ViewBuilder
    private func stepperRow(viewModel: HabitDetailViewModel) -> some View {
        let currentProgress = viewModel.currentProgress
        
        Spacer()
        
        Stepper(value: Binding(
            get: { currentProgress },
            set: { newValue in
                let difference = newValue - currentProgress
                if difference > 0 {
                    for _ in 0..<difference {
                        viewModel.incrementProgress()
                    }
                } else if difference < 0 {
                    for _ in 0..<abs(difference) {
                        viewModel.decrementProgress()
                    }
                }
                HapticManager.shared.playSelection()
            }
        ), in: 0...Int.max) {}
    }
    
    @ViewBuilder
    private func sliderRow(viewModel: HabitDetailViewModel) -> some View {
        let currentProgress = viewModel.currentProgress
        let maxValue = Double(habit.goal)
        
        Slider(
            value: Binding(
                get: { Double(currentProgress) },
                set: { newValue in
                    let rounded = Int(newValue.rounded())
                    if rounded != currentProgress {
                        viewModel.setProgress(rounded)
                        HapticManager.shared.playSelection()
                    }
                }
            ),
            in: 0...maxValue,
            step: 1
        )
        .tint(habit.iconColor.color)
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func completeButtonView(viewModel: HabitDetailViewModel) -> some View {
            Button(action: {
                if !viewModel.isAlreadyCompleted {
                    HapticManager.shared.playImpact(.medium)
                }
                viewModel.completeHabit()
            }) {
                Text(viewModel.isAlreadyCompleted ? "completed".localized : "complete".localized)
                    .font(.system(size: 17, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(viewModel.isAlreadyCompleted ? Color.secondary : Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
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
