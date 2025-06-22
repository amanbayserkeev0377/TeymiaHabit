import SwiftUI

struct IconSection: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    
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
                
                Text("icon".localized)
                
                Spacer()
                
                // Показываем выбранную иконку с ее цветом
                if let selectedIcon = selectedIcon {
                    Image(systemName: selectedIcon)
                        .foregroundStyle(selectedColor.color)
                        .font(.system(size: 16))
                }
            }
        }
    }
}
