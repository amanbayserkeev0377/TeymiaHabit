import SwiftUI
import SwiftData

struct SettingsView: View {
    
    var body: some View {
        List {
            ProRowView()
            
            Section {
                AppIconRowView()
                AppearanceRowView()
                WeekStartRowView()
                LanguageRowView()
            }
            
            Section {
                SoundRowView()
                NotificationsRowView()
                HapticsRowView()
                
            }
            
            Section {
                ArchiveRowView()
            }
            
            AboutSection()
            
#if DEBUG
            Section {
                Button("Toggle Pro Status") {
                    ProManager.shared.toggleProStatusForTesting()
                }
            }
#endif
        }
        .navigationTitle("settings")
    }
}
