import SwiftUI

struct NewTaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedColor: HabitIconColor = .blue
    @State private var selectedIcon: String = "list.bullet"

    // Quick icon options for lists
    private let quickIcons = [
        "list.bullet", "star.fill", "heart.fill", "briefcase.fill",
        "house.fill", "cart.fill", "book.fill", "figure.run",
        "gamecontroller.fill", "music.note", "car.fill", "airplane"
    ]

    var body: some View {
        NavigationStack {
            List {
                // Preview
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(selectedColor.color.gradient.opacity(0.15))
                                    .frame(width: 60, height: 60)

                                Image(systemName: selectedIcon)
                                    .font(.system(size: 24))
                                    .foregroundStyle(selectedColor.color.gradient)
                            }

                            Text(title.isEmpty ? "List Name" : title)
                                .font(.headline)
                                .foregroundStyle(title.isEmpty ? .secondary : .primary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // Title
                Section {
                    TextField("List Name", text: $title)
                        .fontWeight(.medium)
                }

                // Icon picker
                Section("Icon") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 6),
                        spacing: 12
                    ) {
                        ForEach(quickIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                HapticManager.shared.playSelection()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon
                                              ? Color.primary
                                              : Color.secondary)
                                        .frame(width: 44, height: 44)

                                    Image(systemName: icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(selectedIcon == icon
                                                         ? selectedColor.color.gradient
                                                         : Color.secondary.gradient)
                                }
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3), value: selectedIcon)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                CloseToolbarButton()
                ConfirmationToolbarButton(
                    action: {
                        let newList = TaskList(
                            title: title.trimmingCharacters(in: .whitespaces),
                            iconName: selectedIcon,
                            color: selectedColor
                        )
                        modelContext.insert(newList)
                        dismiss()
                    },
                    isDisabled: title.trimmingCharacters(in: .whitespaces).isEmpty
                )
            }
        }
    }
}
