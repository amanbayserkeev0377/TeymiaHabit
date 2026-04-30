import SwiftUI

enum SettingDetail: Hashable, CaseIterable {
    case appearance, appIcon, notifications, sound, archive
}

struct SettingsView: View {
    @State private var selectedDetail: SettingDetail? = .appearance
    
    var body: some View {
        NavigationSplitView {
            Form {
                Section {
                    settingRow(for: .appearance) { AppearanceRow() }
                    #if os(iOS)
                    settingRow(for: .appIcon) { AppIconRow() }
                    #endif
                    settingRow(for: .notifications) { NotificationsRow() }
                    settingRow(for: .sound) { SoundRow() }
                    settingRow(for: .archive) { ArchiveRow() }
                    
                    #if os(iOS)
                    LanguageRow()
                    #endif
                }
                
                AboutSection()
            }
            .navigationTitle("settings")
            .listStyle(.sidebar)
        } detail: {
            if let detail = selectedDetail {
                destinationView(for: detail)
            } else {
                Text("Select an option")
            }
        }
    }
    
    @ViewBuilder
    private func settingRow<Content: View>(for detail: SettingDetail, @ViewBuilder content: () -> Content) -> some View {
        Button {
            selectedDetail = detail
        } label: {
            content()
        }
        .foregroundStyle(.primary)
    }
    
    @ViewBuilder
    private func destinationView(for detail: SettingDetail) -> some View {
        switch detail {
        case .appearance:
            Text("Appearance Settings View")
        case .appIcon:
            #if os(iOS)
            AppIconView()
            #endif
        case .notifications:
            Text("Notifications Settings View")
        case .sound:
            Text("Sound Settings View")
        case .archive:
            Text("Archive Settings View")
        }
    }
    
    #if os(iOS)
    private struct LanguageRow: View {
        var body: some View {
            Button(action: openAppSettings) {
                HStack {
                    Label(
                        title: { Text("settings_language") },
                        icon: { RowIcon(iconName: "globe.americas.fill") }
                    )
                    Spacer()
                    Text(currentLanguage).foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }
        
        private func openAppSettings() {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
        
        private var currentLanguage: String {
            let languageCode = Bundle.main.preferredLocalizations.first ?? "en"
            return Locale.current.localizedString(forLanguageCode: languageCode)?.capitalized ?? languageCode
        }
    }
    #endif
}
