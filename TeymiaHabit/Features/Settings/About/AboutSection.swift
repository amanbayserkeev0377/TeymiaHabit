import SwiftUI

struct AboutSection: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Section {
            // Rate
            settingsButton("settings_rate", icon: "star") {
                openURL(AppConfig.rateAppURL)
            }
            
            // Share
            ShareLink(item: AppConfig.appStoreURL) {
                settingsLabel("settings_share", icon: "square.and.arrow.up")
            }
            
            // Privacy Policy
            settingsButton("settings_privacy_policy", icon: "lock") {
                openURL(AppConfig.privacyPolicyURL)
            }
            
            // Terms of Service
            settingsButton("settings_tos", icon: "document") {
                openURL(AppConfig.termsOfServiceURL)
            }
        } footer: {
            Text("Teymia Habit \(Bundle.main.appVersion)")
        }
    }
    
    private func settingsButton(_ title: LocalizedStringKey, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            settingsLabel(title, icon: icon)
        }
    }
    
    private func settingsLabel(_ title: LocalizedStringKey, icon: String) -> some View {
        Label {
            Text(title).foregroundStyle(.primary)
        } icon: {
            RowIcon(iconName: icon)
        }
    }
}
