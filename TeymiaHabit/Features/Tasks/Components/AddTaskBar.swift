import SwiftUI

struct AddTaskBar: View {
    @Binding var title: String
    @FocusState.Binding var isFocused: Bool
    var onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Add Task", text: $title)
                .focused($isFocused)
                .padding(12)
                .tint(Color.primary)
            
            HStack {
                Button("", systemImage: "calendar") {
                    
                }
                
                Spacer()
                
                Button(action: onSave) {
                    Image(systemName: "arrow.up")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primaryInverse)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .contentShape(.circle)
                .glassEffect(.regular.interactive().tint(Color.primary), in: .circle)
                .disabled(title.isEmpty)
            }
            .padding(12)
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
    }
}
