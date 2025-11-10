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
                            Image("sounds")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.red.gradient)
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
                            Image("icloud")
                                .resizable()
                                .frame(width: 24, height: 24)
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
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.gray.gradient)
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
                            Image("export")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.gray.gradient)
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
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(.green.gradient)
                            }
                        )
                        Spacer()
                        Text(privacyStatusText)
                            .fontDesign(.rounded)
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
                                .frame(width: 24, height: 24)
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
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.red.gradient)
                            
                            Text("in_kyrgyzstan".localized)
                            
                            Image("kyrgyzstan")
                                .resizable()
                                .frame(width: 24, height: 24)
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
