import SwiftUI

// MARK: - Common AlertState
struct AlertState: Equatable {
    var isDeleteAlertPresented: Bool = false
    var date: Date? = nil
    
    var successFeedbackTrigger: Bool = false
    var errorFeedbackTrigger: Bool = false
    
    static func == (lhs: AlertState, rhs: AlertState) -> Bool {
        return lhs.isDeleteAlertPresented == rhs.isDeleteAlertPresented &&
        lhs.date?.timeIntervalSince1970 == rhs.date?.timeIntervalSince1970
    }
}

// MARK: - Habit Delete Alerts

// Single Habit Delete Alert
struct DeleteSingleHabitAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let habitName: String
    let onDelete: () -> Void
    let habit: Habit?
    
    func body(content: Content) -> some View {
        content
            .alert("alert_delete_habit".localized, isPresented: $isPresented) {
                Button("button_cancel".localized, role: .cancel) { }
                Button("button_delete".localized, role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("alert_delete_habit_message".localized(with: habitName))
            }
        // ✅ Цвет привычки для alert
            .tint(habit?.iconColor.color ?? AppColorManager.shared.selectedColor.color)
    }
}

// MARK: - View Extensions

extension View {
    // MARK: - Habit Delete Alert Extensions
    
    /// Alert for deleting a single habit
    func deleteSingleHabitAlert(
        isPresented: Binding<Bool>,
        habitName: String,
        onDelete: @escaping () -> Void,
        habit: Habit? = nil
    ) -> some View {
        self.modifier(DeleteSingleHabitAlertModifier(
            isPresented: isPresented,
            habitName: habitName,
            onDelete: onDelete,
            habit: habit
        ))
    }
}
