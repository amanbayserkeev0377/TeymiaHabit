import SwiftUI

struct LanguageSection: View {
    private var currentLanguage: String {
        let locale = Locale.current
        guard let languageCode = locale.language.languageCode?.identifier else {
            return "Unknown"
        }
        
        let languageName = locale.localizedString(forLanguageCode: languageCode) ?? languageCode
        
        return languageName.prefix(1).uppercased() + languageName.dropFirst()
    }
    
    var body: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Label(
                    title: { Text("language".localized) },
                    icon: {
                        Image("globe.ui")
                            .settingsIcon()
                    }
                )
                
                Spacer()
                
                Text(currentLanguage)
                    .foregroundStyle(.secondary)
                    .fontDesign(.rounded)
            }
        }
        .tint(.primary)
    }
}
