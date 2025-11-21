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
            .listRowBackground(Color.mainRowBackground)

            
            Section {
                NavigationLink {
                    SoundSettingsView()
                } label: {
                    Label(
                        title: { Text("sounds".localized) },
                        icon: {
                            Image("sounds")
                                .settingsIcon()
                        }
                    )
                }
                NotificationsSection()
                HapticsSection()
            }
            .listRowBackground(Color.mainRowBackground)

            
            Section {
                NavigationLink {
                    CloudKitSyncView()
                } label: {
                    Label(
                        title: { Text("icloud_sync".localized) },
                        icon: {
                            Image("icloud")
                                .settingsIcon()
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
                                Image("archive")
                                    .settingsIcon()
                            }
                        )
                    }
                }
                
                NavigationLink {
                    ExportDataView()
                } label: {
                    Label(
                        title: { Text("export_data".localized) },
                        icon: {
                            Image("export")
                                .settingsIcon()
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
                                Image("faceid")
                                    .settingsIcon()
                            }
                        )
                        Spacer()
                        Text(privacyStatusText)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listRowBackground(Color.mainRowBackground)
            
            AboutSection()
            
            Section {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        Button {
                            if let url = URL(string: "https://github.com/amanbayserkeev0377/Teymia-Habit") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image("github")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            if let url = URL(string: "https://instagram.com/teymiapps") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image("instagram")
                                .resizable()
                                .frame(width: 22, height: 22)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    VStack(spacing: 4) {
                        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.5"
                        
                        Text("Teymia Habit – \("version".localized) \(version)")
                            .font(.subheadline)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 4) {
                            Text("made_with".localized)
                            
                            Image("heart.fill")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(Color.secondary)
                            
                            Text("in_kyrgyzstan".localized)
                            
                            Image("kyrgyzstan")
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        .font(.subheadline)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.mainGroupBackground)
        .navigationTitle("settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Private Methods
    
    private var privacyStatusText: String {
        PrivacyManager.shared.isPrivacyEnabled ? "on".localized : "off".localized
    }
}
