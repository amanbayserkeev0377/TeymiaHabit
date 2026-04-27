import Foundation

enum AppConfig {
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6746747903")!
    static let rateAppURL = URL(string: "https://apps.apple.com/app/id6746747903?action=write-review")!
    static let privacyPolicyURL = URL(string: "https://www.notion.so/Privacy-Policy-1ffd5178e65a80d4b255fd5491fba4a8")!
    static let termsOfServiceURL = URL(string: "https://www.notion.so/Terms-of-Service-204d5178e65a80b89993e555ffd3511f")!
}

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1"
    }
}
