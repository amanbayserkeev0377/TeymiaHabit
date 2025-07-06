import SwiftUI

struct TimeInputView: View {
    
    // MARK: - Properties
    let habit: Habit
    @Binding var isPresented: Bool
    let onConfirm: (Int, Int) -> Void
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    @State private var selectedTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            Text("add_time".localized)
                .font(.headline)
                .foregroundStyle(.primary)
            
            // ✅ НАТИВНЫЙ DatePicker с hourAndMinute
            DatePicker(
                "Time",
                selection: $selectedTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxHeight: 140)
            
            // Buttons
            HStack(spacing: 12) {
                // Cancel button
                Button {
                    isPresented = false
                } label: {
                    Text("button_cancel".localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(habit.iconColor.color)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(habit.iconColor.color.opacity(0.1))
                        )
                }
                
                // Add button
                Button {
                    let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                    let hours = components.hour ?? 0
                    let minutes = components.minute ?? 0
                    
                    onConfirm(hours, minutes)
                    isPresented = false
                } label: {
                    Text("button_add".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(habit.iconColor.adaptiveGradient(for: colorScheme))
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .padding(.horizontal, 32)
    }
}

/*
✅ ИСПРАВЛЕНИЯ:

1. УБРАН ФОН:
   - Нет больше ZStack с Color.black
   - Только карточка с содержимым

2. ПОЛНЫЕ КНОПКИ:
   - Button { } label: { } вместо Button("text") { }
   - Весь Text + background в label
   - Теперь вся область кликабельна

3. СТРУКТУРА:
   - Только VStack с карточкой
   - Готов к внешним анимациям
   - Чистый и простой код

🎯 РЕЗУЛЬТАТ: Карточка без фона, полностью кликабельные кнопки!
*/
