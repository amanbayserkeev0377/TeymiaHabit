import SwiftUI

struct NameFieldSection: View {
    @Binding var title: String
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil")
                .withIOSSettingsIcon(lightColors: [
                    Color(#colorLiteral(red: 1, green: 0.6, blue: 0.2, alpha: 1)), // Оранжевый
                    Color(#colorLiteral(red: 0.9, green: 0.4, blue: 0.1, alpha: 1))  // Темно-оранжевый
                ], fontSize: 19
                )
            
            HStack {
                TextField("habit_name".localized, text: $title)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                
                // Clear button - показываем только когда есть текст
                if !title.isEmpty {
                    Button(action: {
                        title = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
