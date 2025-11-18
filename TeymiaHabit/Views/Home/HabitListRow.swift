import SwiftUI
import SwiftData

struct HabitListRow: View {
    let habit: Habit
    let date: Date
    let viewModel: HabitDetailViewModel?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    private let ringSize: CGFloat = 48
    private let lineWidth: CGFloat = 6
    
    @State private var timerUpdateTrigger = 0
    @State private var cardTimer: Timer?
    @State private var hasPlayedCompletionSound = false
    
    private var isTimerActive: Bool {
        guard habit.type == .time && Calendar.current.isDateInToday(date) else {
            return false
        }
        
        let habitId = habit.uuid.uuidString
        return TimerService.shared.isTimerRunning(for: habitId)
    }
    
    private var cardProgress: Int {
        _ = timerUpdateTrigger
        
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
        guard habit.goal > 0 else { return 0 }
        return Double(cardProgress) / Double(habit.goal)
    }
    
    private var cardIsCompleted: Bool {
        cardProgress >= habit.goal
    }
    
    private var cardIsExceeded: Bool {
        cardProgress > habit.goal
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            HabitIconView(iconName: habit.iconName, color: habit.iconColor)
            
            // Title + Progress
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                
                Text("\(formattedProgress) / \(habit.formattedGoal)")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
            
            Spacer()
            
            // Interactive Progress Ring
            Button(action: {
                handleRingTap()
            }) {
                ProgressRing.compactInteractive(
                    progress: cardCompletionPercentage,
                    isCompleted: cardIsCompleted,
                    isExceeded: cardIsExceeded,
                    habit: habit,
                    isTimerRunning: isTimerActive,
                    size: ringSize,
                    lineWidth: lineWidth
                )
                .opacity(0.8)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onAppear {
            if isTimerActive {
                startCardTimer()
            }
        }
        .onDisappear {
            stopCardTimer()
        }
        .onChange(of: timerUpdateTrigger) { _, _ in
            if isTimerActive {
                checkTimerCompletion()
            }
        }
        .onChange(of: isTimerActive) { _, newValue in
            if newValue {
                startCardTimer()
                hasPlayedCompletionSound = false
            } else {
                stopCardTimer()
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
    
    private func startCardTimer() {
        stopCardTimer()
        
        cardTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timerUpdateTrigger += 1
        }
    }
    
    private func stopCardTimer() {
        cardTimer?.invalidate()
        cardTimer = nil
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
