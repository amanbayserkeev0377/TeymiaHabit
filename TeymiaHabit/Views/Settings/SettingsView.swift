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
                
                // Data
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
                    
                    // Archived habits
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
                    
                    //Passcode & Face ID
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
                
                // Legal
                AboutSection()
                                
                // Teymia Habit - version ...
                Section {
                    VStack(spacing: 4) {
                        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2"
                        
                        Image("TeymiaHabitBlank")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                        
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
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("settings".localized)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private var privacyStatusText: String {
        if PrivacyManager.shared.isPrivacyEnabled {
            return "on".localized
        } else {
            return "off".localized
        }
    }
}
