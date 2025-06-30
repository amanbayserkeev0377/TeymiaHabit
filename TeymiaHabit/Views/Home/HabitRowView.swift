import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let date: Date
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private let ringSize: CGFloat = 58
    private let lineWidth: CGFloat = 7.0
    private let iconSize: CGFloat = 23
    
    private var adaptedFontSize: CGFloat {
        let value = habit.formattedProgressValue(for: date)
        let baseSize = ringSize * 0.32
        
        let digitsCount = value.filter { $0.isNumber }.count
        let factor: CGFloat = digitsCount <= 3 ? 1.0 : (digitsCount == 4 ? 0.85 : 0.7)
        
        return baseSize * factor
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Icon - увеличенная
                let iconName = habit.iconName ?? "checkmark"
                
                // Icon с pin overlay
                ZStack(alignment: .topTrailing) {
                    // Основная иконка
                    Image(systemName: iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(habit.iconColor.color)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(habit.iconColor.adaptiveGradient(for: colorScheme)
                                    .opacity(0.2)
                                )
                        )
                    
                    // Pin indicator badge
                    if habit.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColorManager.shared.selectedColor.color)
                            .frame(width: 18, height: 18)
                    }
                }
                
                // Title and goal
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("goal_format".localized(with: habit.formattedGoal))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Progress ring
                ProgressRing(
                    progress: habit.completionPercentageForDate(date),
                    currentValue: habit.formattedProgressValue(for: date),
                    isCompleted: habit.isCompletedForDate(date),
                    isExceeded: habit.isExceededForDate(date),
                    habit: habit,
                    size: ringSize,
                    lineWidth: lineWidth,
                    fontSize: adaptedFontSize,
                    iconSize: iconSize
                )
            }
        }
    }
}
