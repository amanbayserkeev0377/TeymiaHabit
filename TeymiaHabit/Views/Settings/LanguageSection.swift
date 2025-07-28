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
                        Image(systemName: "globe.americas.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.4, green: 0.7, blue: 0.95, alpha: 1)),
                                Color(#colorLiteral(red: 0.12, green: 0.35, blue: 0.6, alpha: 1))
                            ])
                    }
                )
                
                Spacer()
                
                Text(currentLanguage)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "arrow.up.right")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundStyle(.tertiary)
            }
        }
        .tint(.primary)
    }
}
