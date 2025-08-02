import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.privacyManager) private var privacyManager
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    
    @State private var showingPaywall = false
    @State private var showingRestoreAlert = false
    @State private var restoreAlertMessage = ""
    @State private var isRestoring = false
    
    var body: some View {
        List {
            ProSettingsSection()
            
#if DEBUG
            Section("Debug Controls") {
                Button("Toggle Pro Status") {
                    ProManager.shared.toggleProStatusForTesting()
                }
            }
#endif
            
            Section {
                AppearanceSection()
                WeekStartSection()
                LanguageSection()
            }
            
            Section {
                NavigationLink {
                    SoundSettingsView()
                } label: {
                    Label(
                        title: { Text("sounds".localized) },
                        icon: {
                            Image(systemName: "speaker.wave.2.fill")
                                .withIOSSettingsIcon(lightColors: [
                                    Color(#colorLiteral(red: 1, green: 0.3, blue: 0.3, alpha: 1)),
                                    Color(#colorLiteral(red: 0.8, green: 0.1, blue: 0.1, alpha: 1))
                                ])
                        }
                    )
                }
                NotificationsSection()
                HapticsSection()
            }
            
            Section {
                NavigationLink {
                    CloudKitSyncView()
                } label: {
                    Label(
                        title: { Text("icloud_sync".localized) },
                        icon: {
                            Image(systemName: "icloud.fill")
                                .withGradientIcon(
                                    colors: [
                                        Color(#colorLiteral(red: 0.5846864419, green: 0.8865533615, blue: 1, alpha: 1)),
                                        Color(#colorLiteral(red: 0.2244010968, green: 0.5001963656, blue: 0.9326009076, alpha: 1))
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        }
                    )
                }
                
                NavigationLink {
                    ArchivedHabitsView()
                } label: {
                    HStack {
                        Label(
                            title: { Text("archived_habits".localized) },
                            icon: {
                                Image(systemName: "archivebox.fill")
                                    .withIOSSettingsIcon(lightColors: [
                                        Color(#colorLiteral(red: 0.7333333333, green: 0.7333333333, blue: 0.7607843137, alpha: 1)),
                                        Color(#colorLiteral(red: 0.3019607843, green: 0.3019607843, blue: 0.3254901961, alpha: 1))
                                    ])
                            }
                        )
                        Spacer()
                        ArchivedHabitsCountBadge()
                    }
                }
                
                NavigationLink {
                    ExportDataView()
                } label: {
                    Label(
                        title: { Text("export_data".localized) },
                        icon: {
                            Image(systemName: "arrow.up.document.fill")
                                .withIOSSettingsIcon(lightColors: [
                                    Color(#colorLiteral(red: 0.7333333333, green: 0.7333333333, blue: 0.7607843137, alpha: 1)),
                                    Color(#colorLiteral(red: 0.3019607843, green: 0.3019607843, blue: 0.3254901961, alpha: 1))
                                ])
                        }
                    )
                }
                
                NavigationLink {
                    PrivacySettingsView()
                } label: {
                    HStack {
                        Label(
                            title: { Text("passcode_faceid".localized) },
                            icon: {
                                Image(systemName: "faceid")
                                    .withIOSSettingsIcon(lightColors: [
                                        Color(#colorLiteral(red: 0.4666666667, green: 0.8666666667, blue: 0.4, alpha: 1)),
                                        Color(#colorLiteral(red: 0.1176470588, green: 0.5647058824, blue: 0.1176470588, alpha: 1))
                                    ])
                            }
                        )
                        Spacer()
                        Text(privacyStatusText)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            AboutSection()
            
            Section {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        Button {
                            if let url = URL(string: "https://github.com/amanbayserkeev0377/Teymia-Habit") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image("3d_soc_github")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button {
                            if let url = URL(string: "https://instagram.com/teymia.habit") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image("3d_soc_instagram")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    VStack(spacing: 4) {
                        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.4"
                        
                        Text("Teymia Habit – \("version".localized) \(version)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 4) {
                            Text("made_with".localized)
                            Image(systemName: "heart.fill")
                            Text("in_kyrgyzstan".localized)
                            Text("🇰🇬")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, -16)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("settings".localized)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Private Methods
    
    private var privacyStatusText: String {
        PrivacyManager.shared.isPrivacyEnabled ? "on".localized : "off".localized
    }
}
