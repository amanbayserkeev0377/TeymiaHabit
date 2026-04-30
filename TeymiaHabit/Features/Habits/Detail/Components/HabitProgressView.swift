import SwiftUI

struct HabitProgressView: View {
    let viewModel: HabitDetailViewModel
    let habit: Habit
    
    private enum Layout {
        static let minRingSize: CGFloat = 140
        static let maxRingSize: CGFloat = 300
        static let ringWidthRatio: CGFloat = 0.5
        static let buttonSizeRatio: CGFloat = 0.25
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let adaptiveSize = min(
                max(availableWidth * Layout.ringWidthRatio, Layout.minRingSize),
                Layout.maxRingSize
            )
            
            let adaptiveButtonSize = adaptiveSize * Layout.buttonSizeRatio
            
            HStack(spacing: DS.Spacing.s16) {
                Spacer()
                
                actionButton(
                    systemName: "minus",
                    size: adaptiveButtonSize,
                    action: viewModel.decrementProgress,
                    isDisabled: viewModel.currentProgress <= 0
                )
                
                Spacer()
                
                ProgressRing(
                    progress: viewModel.completionPercentage,
                    currentValue: "\(viewModel.currentProgress)",
                    isCompleted: viewModel.isAlreadyCompleted,
                    isExceeded: viewModel.currentProgress > habit.goal,
                    habit: habit,
                    size: adaptiveSize
                )
                
                Spacer()
                
                actionButton(
                    systemName: "plus",
                    size: adaptiveButtonSize,
                    action: viewModel.incrementProgress
                )
                
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: Layout.maxRingSize)
        .padding(.horizontal, DS.Spacing.s24)
    }
    
    // MARK: - Subviews
    private func actionButton(systemName: String, size: CGFloat, action: @escaping () -> Void, isDisabled: Bool = false) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(Color.primary)
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(false).tint(DS.Colors.appSecondary), in: .circle)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1.0)
    }
}
