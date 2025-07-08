import SwiftUI

struct ProgressControlSection: View {
    let habit: Habit
    @Binding var currentProgress: Int
    let completionPercentage: Double
    let formattedProgress: String
    
    var onIncrement: () -> Void
    var onDecrement: () -> Void
        
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
        
    private var isCompleted: Bool {
        completionPercentage >= 1.0
    }
    
    private var isExceeded: Bool {
        Double(currentProgress) > Double(habit.goal)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            // ✅ КНОПКА МИНУС (-1)
            Button(action: {
                onDecrement()
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(habit.iconColor.color)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        Circle()
                            .fill(
                                habit.iconColor.adaptiveGradient(for: colorScheme)
                                    .opacity(0.15)
                            )
                    )
            }
            .disabled(currentProgress <= 0)
            
            Spacer()
            
            ProgressRing(
                progress: completionPercentage,
                currentValue: formattedProgress,
                isCompleted: isCompleted,
                isExceeded: isExceeded,
                habit: habit,
                size: 200,
                lineWidth: 18,
                fontSize: 38
            )
            .aspectRatio(1, contentMode: .fit)
            
            Spacer()
            
            // ✅ КНОПКА ПЛЮС (+1)
            Button(action: {
                onIncrement()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(habit.iconColor.color)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        Circle()
                            .fill(
                                habit.iconColor.adaptiveGradient(for: colorScheme)
                                    .opacity(0.15)
                            )
                    )
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
