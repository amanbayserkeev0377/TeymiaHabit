import SwiftUI

// MARK: - About Section

struct AboutSection: View {
    var body: some View {
        Section {
            // Rate App
            Button {
                if let url = URL(string: "https://apps.apple.com/app/id6746747903") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("rate_app".localized) },
                    icon: {
                        Image("star")
                            .settingsIcon()
                    }
                )
            }
            .tint(.primary)
            
            // Share App
            ShareLink(
                item: URL(string: "https://apps.apple.com/app/id6746747903")!
            ) {
                Label(
                    title: { Text("share_app".localized) },
                    icon: {
                        Image("share")
                            .settingsIcon()
                    }
                )
            }
            .tint(.primary)
            
            // Privacy Policy
            Button {
                if let url = URL(string: "https://www.notion.so/Privacy-Policy-1ffd5178e65a80d4b255fd5491fba4a8") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("privacy_policy".localized) },
                    icon: {
                        Image("lock")
                            .settingsIcon()
                    }
                )
            }
            .tint(.primary)
            
            // Terms of Service
            Button {
                if let url = URL(string: "https://www.notion.so/Terms-of-Service-204d5178e65a80b89993e555ffd3511f") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("terms_of_service".localized) },
                    icon: {
                        Image("document")
                            .settingsIcon()
                    }
                )
            }
            .tint(.primary)
            
            // Attributions
            NavigationLink {
                AttributionsView()
            } label: {
                Label(
                    title: { Text("licenses_section_attributions".localized) },
                    icon: {
                        Image("link")
                            .settingsIcon()
                    }
                )
            }
        }
        .listRowBackground(Color.mainRowBackground)
    }
}
