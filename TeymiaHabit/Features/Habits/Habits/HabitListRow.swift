import SwiftUI
import SwiftData

struct HabitListRow: View {
    let habit: Habit
    let date: Date
    let viewModel: HabitDetailViewModel?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerService
    
    private let ringSize: CGFloat = 48
    private let lineWidth: CGFloat = 6
    
    @State private var hasPlayedCompletionSound = false
    
    private var isTimerActive: Bool {
        guard habit.modelContext != nil else { return false }
        
        guard habit.type == .time && Calendar.current.isDateInToday(date) else {
            return false
        }
        
        let habitId = habit.uuid.uuidString
        return TimerService.shared.isTimerRunning(for: habitId)
    }
    
    private var cardProgress: Int {
        guard habit.modelContext != nil else { return 0 }
        let _ = timerService.updateTrigger
        
        if isTimerActive {
            if let liveProgress = TimerService.shared.getLiveProgress(for: habit.uuid.uuidString) {
                return liveProgress
            }
        }
        
        if let viewModel = viewModel {
            return viewModel.currentProgress
        }
        
        return habit.progressForDate(date)
    }
    
    private var formattedProgress: String {
        habit.formatProgress(cardProgress)
    }
    
    private var cardCompletionPercentage: Double {
        guard habit.modelContext != nil, habit.goal > 0 else { return 0 }
        return Double(cardProgress) / Double(habit.goal)
    }
    
    private var cardIsCompleted: Bool {
        cardProgress >= habit.goal
    }
    
    private var cardIsExceeded: Bool {
        cardProgress > habit.goal
    }
    
    var body: some View {
        if habit.modelContext == nil {
            Color.clear.frame(height: 1)
        } else {
            HStack(spacing: 12) {
                // Icon
                HabitIconView(iconName: habit.iconName, iconColor: habit.iconColor)
                
                // Title + Progress
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Text("\(formattedProgress) / \(habit.formattedGoal)")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                }
                
                Spacer()
                
                // Interactive Progress Ring
                Button(action: {
                    handleRingTap()
                }) {
                    ProgressRing(
                        progress: cardCompletionPercentage,
                        currentValue: "",
                        isCompleted: cardIsCompleted,
                        isExceeded: cardIsExceeded,
                        habit: habit,
                        size: 50,
                        isTimerRunning: isTimerActive
                    )
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onChange(of: timerService.updateTrigger) { _, _ in
                if isTimerActive {
                    checkTimerCompletion()
                }
            }
            .onChange(of: isTimerActive) { _, newValue in
                if newValue {
                    hasPlayedCompletionSound = false
                }
            }
        }
    }
    
    // MARK: - Timer Management
    
    private func checkTimerCompletion() {
        guard isTimerActive,
              let liveProgress = TimerService.shared.getLiveProgress(for: habit.uuid.uuidString),
              !hasPlayedCompletionSound,
              habit.progressForDate(date) < habit.goal,
              liveProgress >= habit.goal else { return }
        
        hasPlayedCompletionSound = true
        SoundManager.shared.playCompletionSound()
        HapticManager.shared.play(.success)
    }
    
    // MARK: - Habit Interaction
    
    private func handleRingTap() {
        switch habit.type {
        case .count:
            // For count habits: add +1 directly to habit
            let oldProgress = cardProgress
            habit.addToProgress(1, for: date, modelContext: modelContext)
            HapticManager.shared.playImpact(.light)
            
            // Play sound if just completed (check AFTER update)
            if oldProgress < habit.goal && oldProgress + 1 >= habit.goal {
                SoundManager.shared.playCompletionSound()
                HapticManager.shared.play(.success)
            }
            
        case .time:
            // For time habits: toggle timer
            let habitId = habit.uuid.uuidString
            
            if isTimerActive {
                // Stop timer and get final progress
                if let finalProgress = TimerService.shared.stopTimer(for: habitId) {
                    // Save final progress directly to habit
                    habit.updateProgress(to: finalProgress, for: date, modelContext: modelContext)
                }
                HapticManager.shared.playImpact(.medium)
            } else {
                // Start timer with current progress as base
                let success = TimerService.shared.startTimer(
                    for: habitId,
                    baseProgress: cardProgress
                )
                
                if success {
                    HapticManager.shared.playImpact(.medium)
                } else {
                    // Failed to start (probably hit max timers limit)
                    HapticManager.shared.playImpact(.rigid)
                }
            }
        }
        
        WidgetUpdateService.shared.reloadWidgets()
    }
}
