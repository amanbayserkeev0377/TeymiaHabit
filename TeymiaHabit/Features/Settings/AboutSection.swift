import SwiftUI

struct AboutSection: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Section {
            // Rate App
            Button {
                if let url = URL(string: "https://apps.apple.com/app/id6746747903") {
                    openURL(url, prefersInApp: true)
                }
            } label: {
                Label(
                    title: { Text("settings_rate").foregroundStyle(Color.primary) },
                    icon: { RowIcon(iconName: "star") }
                )
            }
            
            // Share App
            ShareLink(item: URL(string: "https://apps.apple.com/app/id6746747903")!) {
                Label(
                    title: { Text("settings_share").foregroundStyle(Color.primary) },
                    icon: { RowIcon(iconName: "square.and.arrow.up") }
                )
            }
            
            // Privacy Policy
            Button {
                if let url = URL(string: "https://www.notion.so/Privacy-Policy-1ffd5178e65a80d4b255fd5491fba4a8") {
                    openURL(url, prefersInApp: true)
                }
            } label: {
                Label(
                    title: { Text("settings_privacy_policy").foregroundStyle(Color.primary) },
                    icon: { RowIcon(iconName: "lock") }
                )
            }
            
            // Terms of Service
            Button {
                if let url = URL(string: "https://www.notion.so/Terms-of-Service-204d5178e65a80b89993e555ffd3511f") {
                    openURL(url, prefersInApp: true)
                }
            } label: {
                Label(
                    title: { Text("settings_tos").foregroundStyle(Color.primary) },
                    icon: { RowIcon(iconName: "document") }
                )
            }
        }
        
        // About App
        Section {
            VStack(spacing: 4) {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1"
                
                Text("Teymia Habit \(version)")
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 4) {
                    Text("made_with")
                    
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink.gradient)
                    
                    Text("in_kyrgyzstan")
                    
                    Image("kyrgyzstan")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listSectionSeparator(.hidden)
    }
}
