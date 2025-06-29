import SwiftUI

struct IconSection: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationLink {
            IconPickerView(
                selectedIcon: $selectedIcon,
                selectedColor: $selectedColor
            )
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "paintbrush.pointed.fill")
                    .withIOSSettingsIcon(lightColors: [
                        Color(.purple),
                        Color(.pink)
                    ], fontSize: 16
                    )
                
                Text("icon_and_color".localized)
                
                Spacer()
                
                // Показываем выбранную иконку с градиентным фоном и белой иконкой
                if let selectedIcon = selectedIcon {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(
                                    selectedColor.adaptiveGradient(
                                        for: colorScheme)
                                )
                        )
                }
            }
        }
    }
}
