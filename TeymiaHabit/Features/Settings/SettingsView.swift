import SwiftUI

struct SettingsView: View {
    @Environment(AppDependencyContainer.self) private var appContainer
    
    var body: some View {
            Form {
                Section {
                    AppearanceRow()
#if os(iOS)
                    AppIconRow()
                    LanguageRow()
                    NotificationsRow()
#endif
                    SoundRow()
                    ArchiveRow()
                }
                
                AboutSection()
            }
            .navigationTitle("settings")
            .formStyle(.grouped)
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
            .pickerStyle(.automatic)
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
                        icon: { RowIcon(iconName: "globe") }
                    )
                    
                    Spacer()
                    
                    Text(currentLanguage)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }
        
        private func openAppSettings() {
            #if os(iOS)
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
            #elseif os(macOS)
            guard let url = URL(string: "x-apple.systempreferences:com.apple.preference") else { return }
            NSWorkspace.shared.open(url)
            #endif
        }
        
        private var currentLanguage: String {
            let languageCode = Bundle.main.preferredLocalizations.first ?? "en"
            let locale = Locale.current
            let languageName = locale.localizedString(forLanguageCode: languageCode) ?? languageCode
            
            return languageName.capitalized
        }
    }
}
