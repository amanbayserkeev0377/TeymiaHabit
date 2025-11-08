import SwiftUI
import SwiftData

struct HabitCardView: View {
    let habit: Habit
    let date: Date
    let viewModel: HabitDetailViewModel?
    let onTap: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    let onReorder: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    private let ringSize: CGFloat = 52
    private let lineWidth: CGFloat = 6
    
    @State private var timerUpdateTrigger = 0
    @State private var cardTimer: Timer?
    @State private var isProgressRingPressed = false
    @State private var progressAnimationTrigger = 0
    @State private var hasPlayedCompletionSound = false
    @State private var confettiTrigger = 0
    
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
    
    private var completedTextGradient: AnyShapeStyle {
        AppColorManager.getCompletedBarStyle(for: colorScheme)
    }
    
    private var exceededTextGradient: AnyShapeStyle {
        AppColorManager.getExceededBarStyle(for: colorScheme)
    }
    
    private var progressTextColor: AnyShapeStyle {
        if cardIsExceeded {
            return exceededTextGradient
        } else if cardIsCompleted {
            return completedTextGradient
        } else {
            return AnyShapeStyle(Color.primary)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(
                        Color(.separator).opacity(0.5),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(0.15),
                radius: 10
            )
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            onTap()
        }) {
            HStack(spacing: 16) {
                universalIcon(
                    iconId: habit.iconName,
                    baseSize: 26,
                    color: habit.iconColor,
                    colorScheme: colorScheme
                )
                .frame(width: 54, height: 54)
                .background(
                    Circle()
                        .fill(habit.iconColor.adaptiveGradient(for: colorScheme).opacity(0.15))
                )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.title)
                        .font(.body.weight(.medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                    
                    Text(formattedProgress)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(progressTextColor)
                        .monospacedDigit()
                        .animation(isTimerActive ? .none : .easeInOut(duration: 0.4), value: formattedProgress)
                }
                
                Spacer()
                
                ZStack {
                    ProgressRing.compact(
                        progress: cardCompletionPercentage,
                        isCompleted: cardIsCompleted,
                        isExceeded: cardIsExceeded,
                        habit: habit,
                        size: ringSize,
                        lineWidth: lineWidth
                    )
                }
                .confettiCannon(
                    trigger: $confettiTrigger,
                    num: 15,
                    confettis: [.shape(.circle), .shape(.triangle)],
                    colors: [.orange, .green, .blue, .red, .yellow, .purple, .pink, .cyan],
                    confettiSize: 6.0,
                    rainHeight: 500.0,
                    radius: 120,
                    hapticFeedback: false
                )
                .scaleEffect(isProgressRingPressed ? 1.2 : 1.0)
                .animation(.smooth(duration: 0.4), value: isProgressRingPressed)
                .onTapGesture {
                    HapticManager.shared.playImpact(.medium)
                    
                    isProgressRingPressed = true
                    toggleHabitCompletion()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isProgressRingPressed = false
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 64)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
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
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("button_edit".localized, systemImage: "pencil")
            }
            .withAppGradient()

            Button {
                onReorder()
            } label : {
                Label("reorder".localized, systemImage: "arrow.up.arrow.down")
            }
            .withAppGradient()

            Button {
                onArchive()
            } label: {
                Label("archive".localized, systemImage: "archivebox")
            }
            .withAppGradient()

            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("button_delete".localized, systemImage: "trash")
            }
            .tint(.red)
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
    
    // MARK: - Habit Completion
    
    private func toggleHabitCompletion() {
       guard let viewModel = try? HabitManager.shared.getViewModel(for: habit, date: date, modelContext: modelContext) else {
           return
       }
       
       if cardIsCompleted {
           viewModel.resetProgress()
       } else {
           let wasCompleted = cardIsCompleted
           viewModel.completeHabit()
           SoundManager.shared.playCompletionSound()
           
           if !wasCompleted {
               confettiTrigger += 1
           }
       }
       
       HapticManager.shared.play(.success)
       WidgetUpdateService.shared.reloadWidgets()
    }
}
