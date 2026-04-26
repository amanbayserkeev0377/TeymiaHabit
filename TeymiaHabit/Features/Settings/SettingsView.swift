import SwiftUI

struct SettingsView: View {
//    @Environment(AppDependencyContainer.self) private var appContainer
    @State private var showingThemeChange: Bool = false
    
    var body: some View {
        List {
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
    
    private struct AppearanceRow: View {
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
    
    private struct AppIconRow: View {
        var body: some View {
            NavigationLink(destination: AppIconView()) {
                Label(
                    title: { Text("settings_app_icon") },
                    icon: { RowIcon(iconName: "app.specular") }
                )
            }
        }
    }
    
    private struct SoundRow: View {
        var body: some View {
            NavigationLink(destination: SoundView()) {
                Label(
                    title: { Text("settings_sounds") },
                    icon: { RowIcon(iconName: "speaker.wave.1") }
                )
            }
        }
    }
    
    private struct ArchiveRow: View {
        var body: some View {
            NavigationLink(destination: ArchiveView()) {
                Label(
                    title: { Text("settings_archived_habits") },
                    icon: { RowIcon(iconName: "archivebox") }
                )
            }
        }
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
