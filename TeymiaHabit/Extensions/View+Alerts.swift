import SwiftUI

struct AlertState: Equatable {
    var isDeleteAlertPresented: Bool = false
    var date: Date? = nil
    var successFeedbackTrigger: Bool = false
    var errorFeedbackTrigger: Bool = false
    
    static func == (lhs: AlertState, rhs: AlertState) -> Bool {
        lhs.isDeleteAlertPresented == rhs.isDeleteAlertPresented &&
        lhs.date?.timeIntervalSince1970 == rhs.date?.timeIntervalSince1970
    }
}

private struct DeleteSingleHabitAlertModifier: ViewModifier {
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
            .tint(habit?.iconColor.color ?? AppColorManager.shared.selectedColor.color)
    }
}

extension View {
    func deleteSingleHabitAlert(
        isPresented: Binding<Bool>,
        habitName: String,
        onDelete: @escaping () -> Void,
        habit: Habit? = nil
    ) -> some View {
        modifier(DeleteSingleHabitAlertModifier(
            isPresented: isPresented,
            habitName: habitName,
            onDelete: onDelete,
            habit: habit
        ))
    }
}
