import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
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
                }
                
                Section {
                    HapticsSection()
                    NotificationsSection()
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
}
