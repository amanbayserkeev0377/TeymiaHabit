import SwiftUI

// MARK: - Live Activity Status Indicator
struct LiveActivityStatusView: View {
    let hasActiveLiveActivity: Bool
    let isTimerRunning: Bool
    
    var body: some View {
        if hasActiveLiveActivity {
            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isTimerRunning ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isTimerRunning)
                
                Text("Live Activity Active")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "iphone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.green.opacity(0.1))
                    .stroke(.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Integration for HabitDetailView

extension View {
    @ViewBuilder
    func liveActivityStatusIfNeeded(
        habit: Habit,
        hasActiveLiveActivity: Bool,
        isTimerRunning: Bool
    ) -> some View {
        VStack(spacing: 8) {
            self
            
            // Show Live Activity status for time habits on today
            if habit.type == .time && Calendar.current.isDateInToday(Date()) {
                LiveActivityStatusView(
                    hasActiveLiveActivity: hasActiveLiveActivity,
                    isTimerRunning: isTimerRunning
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: hasActiveLiveActivity)
            }
        }
    }
}
