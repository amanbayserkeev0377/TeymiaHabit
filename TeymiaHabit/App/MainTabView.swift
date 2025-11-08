import SwiftUI

enum ThemeMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image("home.fill")
                Text("home".localized)
            }
            .fontDesign(.rounded)
            
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Image("stats.fill")
                Text("statistics".localized)
            }
            .fontDesign(.rounded)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image("settings.fill")
                Text("settings".localized)
            }
            .fontDesign(.rounded)
        }
        .preferredColorScheme(themeMode.colorScheme)
        .withAppColor()
    }
}
