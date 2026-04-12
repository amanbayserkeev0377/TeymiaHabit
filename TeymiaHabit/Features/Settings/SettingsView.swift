import SwiftUI

struct SettingsView: View {
    @Environment(AppDependencyContainer.self) private var appContainer
    
    var body: some View {
            List {
                Section {
                    AppearanceRow()
#if !targetEnvironment(macCatalyst)
                    LanguageRow()
                    AppIconRow()
#endif
                    SoundRow()
                    NotificationsRow()
                    ArchiveRow()
                }
                
                AboutSection()
            }
            .navigationTitle("settings")
    }
    
    private struct AppearanceRow: View {
        @AppStorage("themeMode") private var themeMode: ThemeMode = .system
        
        var body: some View {
            NavigationLink(destination: AppearanceView()) {
                HStack {
                    Label(
                        title: { Text("settings_appearance") },
                        icon: { RowIcon(iconName: themeMode.iconName) }
                    )
                    Spacer()
                    Text(themeMode.localizedName)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }
    
    private struct LanguageRow: View {
        var body: some View {
            Button(action: openAppSettings) {
                HStack {
                    Label {
                        Text("settings_language")
                            .foregroundStyle(.primary)
                    } icon: {
                        RowIcon(iconName: "globe")
                    }
                    
                    Spacer()
                    
                    Text(currentLanguage)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                .padding(.trailing, 2)
            }
        }
        
        
        private func openAppSettings() {
#if os(iOS)
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
#elseif targetEnvironment(macCatalyst)
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
}
