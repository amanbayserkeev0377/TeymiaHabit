import SwiftUI

struct SettingsView: View {
//    @Environment(AppDependencyContainer.self) private var appContainer
    
    var body: some View {
        Form {
            Section {
                AppearanceRow()
                AppIconRow()
                NotificationsRow()
                SoundRow()
                ArchiveRow()
                LanguageRow()
            }
            
            AboutSection()
        }
        .groupBackground()
        .navigationTitle("settings")
    }
        
    private struct LanguageRow: View {
        var body: some View {
            Button(action: openAppSettings) {
                HStack {
                    Label(
                        title: { Text("settings_language") },
                        icon: { RowIcon(iconName: "globe.americas.fill") }
                    )
                    
                    Spacer()
                    
                    Text(currentLanguage)
                        .foregroundStyle(.secondary)
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
            let locale = Locale.current
            let languageName = locale.localizedString(forLanguageCode: languageCode) ?? languageCode
            
            return languageName.capitalized
        }
    }
}
