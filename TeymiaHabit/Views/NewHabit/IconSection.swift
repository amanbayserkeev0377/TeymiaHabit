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
                    universalIcon(
                        iconId: selectedIcon,
                        baseSize: 24,
                        color: selectedColor,
                        colorScheme: colorScheme
                    )
                    .frame(width: 36, height: 36)
                }
            }
        }
    }
}
