import SwiftUI

struct AlertState: Equatable {
    var isDeleteAlertPresented: Bool = false
}

private struct DeleteSingleHabitAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let habitName: String
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("alert_delete_habit", isPresented: $isPresented) {
                Button("button_cancel", role: .cancel) { }
                Button("button_delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("alert_delete_habit_message \(habitName)")
            }
    }
}

extension View {
    func deleteSingleHabitAlert(
        isPresented: Binding<Bool>,
        habitName: String,
        onDelete: @escaping () -> Void
    ) -> some View {
        self.modifier(DeleteSingleHabitAlertModifier(
            isPresented: isPresented,
            habitName: habitName,
            onDelete: onDelete
        ))
    }
}
