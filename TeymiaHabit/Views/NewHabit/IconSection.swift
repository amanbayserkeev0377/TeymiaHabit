import SwiftUI

struct IconSection: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    @Environment(\.colorScheme) private var colorScheme
    let onShowPaywall: () -> Void
    
    var body: some View {
        NavigationLink {
            IconPickerView(
                selectedIcon: $selectedIcon,
                selectedColor: $selectedColor,
                onShowPaywall: onShowPaywall
            )
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "paintbrush.pointed.fill")
                    .withIOSSettingsIcon(lightColors: [
                        Color(.purple),
                        Color(.pink)
                    ], fontSize: 16)
                
                Text("icon_and_color".localized)
                
                Spacer()
                
                if let selectedIcon = selectedIcon {
                    HabitIconView(
                        iconName: selectedIcon,
                        color: selectedColor,
                        size: 20,
                        showBackground: false
                    )
                }
            }
        }
    }
}
