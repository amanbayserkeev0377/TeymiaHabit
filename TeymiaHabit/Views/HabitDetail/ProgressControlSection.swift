import SwiftUI

struct ProgressControlSection: View {
    let habit: Habit
    @Binding var currentProgress: Int
    let completionPercentage: Double
    let formattedProgress: String
    
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    
    @State private var incrementTrigger: Bool = false
    @State private var decrementTrigger: Bool = false
    
    // ✅ ДОБАВЛЯЕМ для анимации нажатий
    @State private var isIncrementPressed: Bool = false
    @State private var isDecrementPressed: Bool = false
    
    // Определяем, является ли устройство маленьким (iPhone SE)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme  // ✅ Добавляем для градиентов
    
    private var isSmallDevice: Bool {
        UIScreen.main.bounds.width <= 375 // iPhone SE, iPhone 8
    }
    
    private var isCompleted: Bool {
        completionPercentage >= 1.0
    }
    
    private var isExceeded: Bool {
        Double(currentProgress) > Double(habit.goal)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // ✅ ОБНОВЛЕННАЯ кнопка МИНУС
            Button(action: {
                decrementTrigger.toggle()
                onDecrement()
            }) {
                Image(systemName: "minus")
                    .font(.system(size: isSmallDevice ? 22 : 24, weight: .semibold))  // ✅ Добавляем weight
                    .foregroundStyle(.white)  // ✅ Белая иконка для контраста
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        Circle()
                            .fill(
                                // ✅ НОВЫЙ градиентный дизайн
                                habit.iconColor.adaptiveGradient(
                                    for: colorScheme)
                            )
                            .shadow(
                                color: colorScheme == .dark ? .clear : .black.opacity(0.1),
                                radius: colorScheme == .dark ? 0 : 4,
                                x: 0,
                                y: colorScheme == .dark ? 0 : 2
                            )
                    )
            }
            .decreaseHaptic(trigger: decrementTrigger)
            // ✅ ДОБАВЛЯЕМ анимацию нажатия
            .scaleEffect(isDecrementPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isDecrementPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}) { pressing in
                isDecrementPressed = pressing
            }
            .padding(.leading, isSmallDevice ? 18 : 22)
            
            Spacer()
            
            // Адаптивный размер для кольца прогресса
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
            
            // ✅ ОБНОВЛЕННАЯ кнопка ПЛЮС
            Button(action: {
                incrementTrigger.toggle()
                onIncrement()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: isSmallDevice ? 22 : 24, weight: .semibold))  // ✅ Добавляем weight
                    .foregroundStyle(.white)  // ✅ Белая иконка для контраста
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        Circle()
                            .fill(
                                // ✅ НОВЫЙ градиентный дизайн
                                habit.iconColor.adaptiveGradient(
                                    for: colorScheme)
                            )
                            .shadow(
                                color: colorScheme == .dark ? .clear : .black.opacity(0.1),
                                radius: colorScheme == .dark ? 0 : 4,
                                x: 0,
                                y: colorScheme == .dark ? 0 : 2
                            )
                    )
            }
            .increaseHaptic(trigger: incrementTrigger)
            // ✅ ДОБАВЛЯЕМ анимацию нажатия
            .scaleEffect(isIncrementPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isIncrementPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}) { pressing in
                isIncrementPressed = pressing
            }
            .padding(.trailing, isSmallDevice ? 18 : 22)
        }
        .padding(.horizontal, isSmallDevice ? 8 : 16)
    }
}

/*
✅ КЛЮЧЕВЫЕ УЛУЧШЕНИЯ:

1. ДИЗАЙН:
   - Градиенты вместо плоского .opacity(0.1)
   - Белые иконки для лучшего контраста
   - Тени для глубины (только светлая тема)
   - weight: .semibold для иконок

2. АНИМАЦИЯ:
   - Простой scale эффект при нажатии (0.92)
   - onLongPressGesture для отслеживания
   - Плавная анимация 0.15 секунды
   - Отдельный State для каждой кнопки

3. КОНСИСТЕНТНОСТЬ:
   - Тот же adaptiveGradient что везде
   - Те же тени что в BeautifulButtonStyle
   - Белые иконки как в других кнопках
   - lightOpacity: 0.8 как в иконках

🎯 РЕЗУЛЬТАТ: Красивые, отзывчивые кнопки +/- в едином стиле!
*/
