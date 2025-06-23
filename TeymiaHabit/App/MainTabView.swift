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
    
    // What's New state
    @State private var showingWhatsNew = false
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("home".localized, systemImage: "house.fill")
            }
            
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("statistics".localized, systemImage: "chart.line.text.clipboard.fill")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("settings".localized, systemImage: "gearshape.fill")
            }
        }
        .preferredColorScheme(themeMode.colorScheme)
        .withAppColor()
        .onAppear {
            checkAndShowWhatsNew()
        }
        .sheet(isPresented: $showingWhatsNew) {
            WhatsNewView()
        }
    }
    
    // MARK: - What's New Logic
    private func checkAndShowWhatsNew() {
        // Check once when app loads
        if WhatsNewManager.shouldShowWhatsNew() {
            // Small delay to let the app fully load
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showingWhatsNew = true
            }
        }
    }
}
