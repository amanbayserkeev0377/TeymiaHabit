import SwiftUI

// MARK: - External Link Modifier

struct ExternalLinkModifier: ViewModifier {
    var trailingText: String? = nil
    
    func body(content: Content) -> some View {
        HStack {
            content
            Spacer()
            
            if let text = trailingText {
                Text(text)
                    .foregroundStyle(.secondary)
            }
            
            Image(systemName: "arrow.up.right")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.tertiary)
        }
    }
}



extension View {
    func withExternalLinkIcon(trailingText: String? = nil) -> some View {
        self.modifier(ExternalLinkModifier(trailingText: trailingText))
    }
}

// MARK: - About Section

struct AboutSection: View {
    var body: some View {
        Section {
            Button {
                if let url = URL(string: "https://apps.apple.com/app/id6746747903") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("rate_app".localized) },
                    icon: {
                        Image(systemName: "star.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.95, green: 0.85, blue: 0.15, alpha: 1)),
                                Color(#colorLiteral(red: 0.75, green: 0.55, blue: 0.05, alpha: 1))
                            ])
                    }
                )
                .withExternalLinkIcon()
            }
            .tint(.primary)
            
            ShareLink(
                item: URL(string: "https://apps.apple.com/app/id6746747903")!
            ) {
                Label(
                    title: { Text("share_app".localized) },
                    icon: {
                        Image(systemName: "square.and.arrow.up.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.55, green: 0.6, blue: 0.9, alpha: 1)),
                                Color(#colorLiteral(red: 0.15, green: 0.2, blue: 0.45, alpha: 1))
                            ])
                    }
                )
                .withExternalLinkIcon()
            }
            .tint(.primary)
            
            Button {
                if let url = URL(string: "https://t.me/amanbayserkeev0377") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("contact_developer".localized) },
                    icon: {
                        Image(systemName: "paperplane.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.45, green: 0.85, blue: 0.95, alpha: 1)),
                                Color(#colorLiteral(red: 0.15, green: 0.5, blue: 0.75, alpha: 1))
                            ])
                    }
                )
                .withExternalLinkIcon()
            }
            .tint(.primary)
        }
        
        Section {
            Button {
                if let url = URL(string: "https://www.notion.so/Privacy-Policy-1ffd5178e65a80d4b255fd5491fba4a8") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("privacy_policy".localized) },
                    icon: {
                        Image(systemName: "lock.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.7333333333, green: 0.7333333333, blue: 0.7607843137, alpha: 1)),
                                Color(#colorLiteral(red: 0.3019607843, green: 0.3019607843, blue: 0.3254901961, alpha: 1))
                            ])
                    }
                )
                .withExternalLinkIcon()
            }
            .tint(.primary)
            
            Button {
                if let url = URL(string: "https://www.notion.so/Terms-of-Service-204d5178e65a80b89993e555ffd3511f") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("terms_of_service".localized) },
                    icon: {
                        Image(systemName: "text.document.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.7333333333, green: 0.7333333333, blue: 0.7607843137, alpha: 1)),
                                Color(#colorLiteral(red: 0.3019607843, green: 0.3019607843, blue: 0.3254901961, alpha: 1))
                            ])
                    }
                )
                .withExternalLinkIcon()
            }
            .tint(.primary)
            
            NavigationLink {
                LicensesView()
            } label: {
                Label(
                    title: { Text("licenses".localized) },
                    icon: {
                        Image(systemName: "scroll.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.7333333333, green: 0.7333333333, blue: 0.7607843137, alpha: 1)),
                                Color(#colorLiteral(red: 0.3019607843, green: 0.3019607843, blue: 0.3254901961, alpha: 1))
                            ])
                    }
                )
            }
        }
    }
}
