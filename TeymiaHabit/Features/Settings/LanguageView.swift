import SwiftUI

struct LanguageRowView: View {
    var body: some View {
        Button { openAppSettings() }
        label: {
            HStack {
                Label(
                    title: { Text("settings_language").foregroundStyle(Color.primary) },
                    icon: { Image(systemName: "globe.badge.clock").iconStyle() }
                )
                Spacer()
                Text(currentLanguage).foregroundStyle(Color.secondary)

            }
        }
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
