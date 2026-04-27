import SwiftUI

struct AppearanceRow: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
        
    var body: some View {
        Picker(selection: $themeMode) {
            ForEach(ThemeMode.allCases, id: \.self) { mode in
                Text(mode.localizedName).tag(mode)
            }
        } label: {
            Label(
                title: { Text("settings_appearance") },
                icon: { RowIcon(iconName: themeMode.iconName) }
            )
        }
        .pickerStyle(.menu)
        .tint(.secondary)
    }
}
