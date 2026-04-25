import SwiftUI
import SwiftData

struct MainTabView: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationManager.self) private var navManager
    @Environment(AppDependencyContainer.self) private var appContainer
    
    @State private var selectedDate: Date = .now
    
    var body: some View {
        @Bindable var nav = navManager
        
        AnimatedTabView(selection: $nav.selectedTab) {
            // Habits
            Tab.init(AppTab.habits.title, systemImage: AppTab.habits.symbolImage, value: .habits) {
                NavigationStack {
                    HabitsView(selectedDate: $selectedDate)
                }
            }
            
            // Statistics
            Tab.init(AppTab.tasks.title, systemImage: AppTab.tasks.symbolImage, value: .tasks) {
                NavigationStack {
                    //                    StatisticsView()
                    Text("Statistics")
                }
            }
            
            // Settings
            Tab.init(AppTab.settings.title, systemImage: AppTab.settings.symbolImage, value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        } effects: { tab in
            switch tab {
            case .habits: [.bounce]
            case .tasks: [.bounce]
            case .settings: [.rotate]
            }
        }
        .tint(.accent)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

enum AppTab: AnimatedTabSelectionProtocol {
    case habits
    case tasks
    case settings
    
    var symbolImage: String {
        switch self {
        case .habits: return "checkmark.circle.dotted"
        case .tasks: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
    
    var title: LocalizedStringResource {
        switch self {
        case .habits: return "tabview_habits"
        case .tasks: return "tabview_statistics"
        case .settings: return "tabview_settings"
        }
    }
}
