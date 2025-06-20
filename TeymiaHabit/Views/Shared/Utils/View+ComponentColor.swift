import SwiftUI

extension View {
    /// Применяет цвет для UI компонентов (не колец) в зависимости от настроек пользователя
    /// - Parameter habit: Привычка для Habit Colors режима (если nil - fallback на app color)
    func withComponentColor(habit: Habit? = nil) -> some View {
        self.foregroundStyle(AppColorManager.shared.getComponentColor(for: habit))
    }
    
    /// Применяет цвет фона для UI компонентов
    /// - Parameter habit: Привычка для Habit Colors режима
    /// - Parameter opacity: Прозрачность фона (по умолчанию 0.1)
    func withComponentBackground(habit: Habit? = nil, opacity: Double = 0.1) -> some View {
        self.background(
            AppColorManager.shared.getComponentColor(for: habit).opacity(opacity)
        )
    }
    
    /// Получить цвет компонента как Color (для использования в computed properties)
    static func componentColor(for habit: Habit? = nil) -> Color {
        return AppColorManager.shared.getComponentColor(for: habit)
    }
}
