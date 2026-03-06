import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    
    
    var body: some View {
        List {
            ProRowView()
#if DEBUG
            Section {
                Button("Toggle Pro Status") {
                    ProManager.shared.toggleProStatusForTesting()
                }
            }
#endif
            Section {
                AppIconRowView()
                AppearanceRowView()
                WeekStartRowView()
                LanguageRowView()
            }
            .listRowBackground(Color.rowBackground)
                  
            Section {
                SoundRowView()
                NotificationsRowView()
                HapticsRowView()
                
            }
            .listRowBackground(Color.rowBackground)
            
            Section {
                CloudRowView()
                ArchiveRowView()
                ExportRowView()
                PrivacyRowView()
            }
            .listRowBackground(Color.rowBackground)
            
            AboutSection()
        }
        .appBackground()
        .navigationTitle("settings")
    }
}
