import SwiftUI

struct ProgressControlSection: View {
    let habit: Habit
    @Binding var currentProgress: Int
    let completionPercentage: Double
    let formattedProgress: String
    
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    
    // ✅ УБИРАЕМ все анимационные State
    @State private var incrementTrigger: Bool = false
    @State private var decrementTrigger: Bool = false
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    private var isSmallDevice: Bool {
        UIScreen.main.bounds.width <= 375
    }
    
    private var isCompleted: Bool {
        completionPercentage >= 1.0
    }
    
    private var isExceeded: Bool {
        Double(currentProgress) > Double(habit.goal)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // ✅ МИНУС кнопка БЕЗ анимаций
            Button(action: {
                decrementTrigger.toggle()
                onDecrement()
            }) {
                Image(systemName: "minus")
                    .font(.system(size: isSmallDevice ? 22 : 24, weight: .semibold))
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
            .decreaseHaptic(trigger: decrementTrigger)
            .padding(.leading, isSmallDevice ? 18 : 22)
            
            Spacer()
            
            // ✅ PROGRESS RING БЕЗ лишних анимаций
            ProgressRing(
                progress: completionPercentage,
                currentValue: formattedProgress,
                isCompleted: isCompleted,
                isExceeded: isExceeded,
                habit: habit,
                size: isSmallDevice ? 160 : 180
            )
            .aspectRatio(1, contentMode: .fit)
            
            Spacer()
            
            // ✅ ПЛЮС кнопка БЕЗ анимаций
            Button(action: {
                incrementTrigger.toggle()
                onIncrement()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: isSmallDevice ? 22 : 24, weight: .semibold))
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
            .increaseHaptic(trigger: incrementTrigger)
            .padding(.trailing, isSmallDevice ? 18 : 22)
        }
        .padding(.horizontal, isSmallDevice ? 8 : 16)
    }
}
