import SwiftUI
import SwiftData

struct MainTabView: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @Environment(\.modelContext) private var modelContext
    @State private var navigationPath = [PersistentIdentifier]()
    @State private var selectedDate: Date = .now
    @State private var selectedTab: AppTab = .habits
    @Namespace private var zoomNamespace
    
    var body: some View {
        AnimatedTabView(selection: $selectedTab) {
            Tab.init(AppTab.habits.title, systemImage: AppTab.habits.symbolImage, value: .habits) {
                NavigationStack(path: $navigationPath) {
                    HomeView(zoomNamespace: zoomNamespace, navigationPath: $navigationPath, selectedDate: $selectedDate)
                        .navigationDestination(for: PersistentIdentifier.self) { id in
                            if let habit = modelContext.model(for: id) as? Habit {
                                HabitDetailView(habit: habit, date: selectedDate)
                                    .navigationTransition(.zoom(sourceID: habit.persistentModelID, in: zoomNamespace))
                            }
                        }
                }
            }
            
            Tab.init(AppTab.tasks.title, systemImage: AppTab.tasks.symbolImage, value: .tasks) {
                NavigationStack {
                    TasksView()
                }
            }
            
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
        .fontDesign(.rounded)
        .preferredColorScheme(themeMode.colorScheme)
        .tint(.mainApp)
        .onReceive(NotificationCenter.default.publisher(for: .openHabitFromDeeplink)) { notification in
            guard let habit = notification.object as? Habit else { return }
            let habitID = habit.persistentModelID
            
            selectedTab = .habits
            
            if navigationPath.last == habitID { return }
            
            navigationPath.removeAll()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigationPath.append(habitID)
            }
        }
    }
}

enum AppTab: AnimatedTabSelectionProtocol {
    case habits
    case tasks
    case settings
    
    var symbolImage: String {
        switch self {
        case .habits: return "checkmark.circle.dotted"
        case .tasks: return "checklist"
        case .settings: return "gearshape"
        }
    }
    
    var title: LocalizedStringResource {
        switch self {
        case .habits: return "tabview_habits"
        case .tasks: return "tabview_tasks"
        case .settings: return "tabview_settings"
        }
    }
}
