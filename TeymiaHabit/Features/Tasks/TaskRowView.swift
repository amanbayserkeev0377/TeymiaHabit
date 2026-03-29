import SwiftUI
import SwiftData

struct TaskRowView: View {
    let task: TodoTask
    var onToggle: () -> Void

    @Environment(\.modelContext) private var modelContext

    private var subtaskSummary: String? {
        guard let subtasks = task.subtasks, !subtasks.isEmpty else {
            return nil
        }
        
        let done = subtasks.filter { $0.isCompleted }.count
        return "\(done)/\(subtasks.count)"
    }

    private var dueDateLabel: String? {
        guard let date = task.dueDate else { return nil }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    private var dueDateColor: Color {
        guard let date = task.dueDate else { return .secondary }
        if date < Calendar.current.startOfDay(for: Date()) { return .red }
        if Calendar.current.isDateInToday(date) { return .orange }
        return .secondary
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(task.isCompleted ? Color.green : Color.secondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if task.isCompleted {
                        Circle()
                            .fill(Color.green.gradient)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .lineLimit(2)

                // Meta row
                if dueDateLabel != nil || subtaskSummary != nil || task.notes != nil {
                    HStack(spacing: 8) {
                        if let label = dueDateLabel {
                            Label(label, systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(dueDateColor)
                        }

                        if let summary = subtaskSummary {
                            Label(summary, systemImage: "checklist")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if task.notes != nil {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
