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
                ], fontSize: 18
                )
            TextField("habit_name".localized, text: $title)
                .autocorrectionDisabled()
                .focused($isFocused)
        }
    }
}
