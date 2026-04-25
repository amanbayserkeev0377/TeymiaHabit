import SwiftUI

struct SettingsView: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @Environment(AppDependencyContainer.self) private var appContainer
    @State private var showingThemeChange: Bool = false
    
    var body: some View {
            ScrollView {
                LazyVStack(spacing: 24) {
                    CustomSection {
                        AppearanceRow {
                            showingThemeChange.toggle()
                        }
                        CustomDivider()
                        
                        AppIconRow()
                        LanguageRow()
                        NotificationsRow()
                        SoundRow()
                        ArchiveRow()
                    }
                }
                
                AboutSection()
            }
            .background(.groupBackground)
            .navigationTitle("settings")
            .sheet(isPresented: $showingThemeChange) {
                ThemeChangeView()
                    .presentationDetents([.height(ThemeChangeView.sheetHeight)])
                    .presentationDragIndicator(.visible)
            }
    }
        
    private struct AppearanceRow: View {
        @AppStorage("themeMode") private var themeMode: ThemeMode = .system
        var onTap: () -> Void
        
        var body: some View {
            CustomRow(
                title: "settings_appearance",
                icon: themeMode.iconName,
                action: onTap
            )
        }
    }
    
    private struct AppIconRow: View {
        var body: some View {
            NavigationLink(destination: AppIconView()) {
                CustomRow(title: "settings_app_icon", icon: "ui-globe")
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
