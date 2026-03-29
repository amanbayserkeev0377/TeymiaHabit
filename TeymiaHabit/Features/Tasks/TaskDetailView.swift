import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: TodoTask

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var newSubtaskTitle = ""
    @FocusState private var isSubtaskFieldFocused: Bool
    @State private var isAddingSubtask = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Title & Notes
                Section {
                    TextField("Task title", text: $task.title, axis: .vertical)
                        .font(.body.weight(.medium))
                        .lineLimit(1...5)

                    TextField("Notes", text: Binding(
                        get: { task.notes ?? "" },
                        set: { task.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1...10)
                }

                // MARK: - Due Date
                Section {
                    DateRow(task: task)
                }

                // MARK: - Subtasks
                Section {
                    ForEach((task.subtasks ?? []).sorted(by: { !$0.isCompleted && $1.isCompleted })) { subtask in
                        SubtaskRow(subtask: subtask)
                    }
                    .onDelete { indices in
                        deleteSubtasks(at: indices)
                    }

                    if isAddingSubtask {
                        HStack(spacing: 12) {
                            Circle()
                                .strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1.5)
                                .frame(width: 20, height: 20)

                            TextField("New subtask", text: $newSubtaskTitle)
                                .focused($isSubtaskFieldFocused)
                                .submitLabel(.done)
                                .onSubmit { saveSubtask() }
                        }
                    }

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isAddingSubtask = true
                            isSubtaskFieldFocused = true
                        }
                    } label: {
                        Label("Add Subtask", systemImage: "plus")
                            .font(.subheadline)
                    }
                } header: {
                    if !(task.subtasks ?? []).isEmpty || isAddingSubtask {
                        Text("Subtasks")
                    }
                }

                // MARK: - Delete
                Section {
                    Button(role: .destructive) {
                        modelContext.delete(task)
                        dismiss()
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func saveSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            isAddingSubtask = false
            return
        }
        
        let subtask = Subtask(title: trimmed)
        if task.subtasks == nil {
            task.subtasks = []
        }
        task.subtasks?.append(subtask)
        
        newSubtaskTitle = ""
        isSubtaskFieldFocused = true
    }

    private func deleteSubtasks(at indices: IndexSet) {
        let sorted = (task.subtasks ?? []).sorted(by: { !$0.isCompleted && $1.isCompleted })
        for index in indices {
            let subtask = sorted[index]
            if let i = task.subtasks?.firstIndex(where: { $0.id == subtask.id }) {
                task.subtasks?.remove(at: i)
                modelContext.delete(subtask)
            }
        }
    }
}

// MARK: - Subtask Row

struct SubtaskRow: View {
    @Bindable var subtask: Subtask

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.25)) {
                    subtask.isCompleted.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(subtask.isCompleted ? Color.green : Color.secondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 20, height: 20)

                    if subtask.isCompleted {
                        Circle()
                            .fill(Color.green.gradient)
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            TextField("Subtask", text: $subtask.title)
                .font(.subheadline)
                .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                .strikethrough(subtask.isCompleted, color: .secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Date Row

private struct DateRow: View {
    @Bindable var task: TodoTask
    @State private var showDatePicker = false

    var body: some View {
        HStack {
            Label("Due Date", systemImage: "calendar")

            Spacer()

            if let date = task.dueDate {
                Button {
                    withAnimation { showDatePicker.toggle() }
                } label: {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                }

                Button {
                    withAnimation { task.dueDate = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    withAnimation {
                        task.dueDate = Date()
                        showDatePicker = true
                    }
                } label: {
                    Text("None")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }

        if showDatePicker {
            DatePicker(
                "",
                selection: Binding(
                    get: { task.dueDate ?? Date() },
                    set: { task.dueDate = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
        }
    }
}
