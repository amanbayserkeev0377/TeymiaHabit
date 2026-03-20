import SwiftUI
import SwiftData

struct MainTabView: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @Environment(\.modelContext) private var modelContext
    @Environment(TimerService.self) private var timerService
    @Query private var allHabits: [Habit]
    @Namespace private var zoomNamespace
    
    @State private var selectedHabit: Habit? = nil
    @State private var selectedDate: Date = .now
    @State private var selectedTab: AppTab = .habits
    @State private var searchText: String = ""
    @State private var currentRandomColor: Color = .mainBackground
    
    let backgroundColors: [Color] = [
        Color(#colorLiteral(red: 0.4047852159, green: 0.4069823921, blue: 0.4050292969, alpha: 1)), Color(#colorLiteral(red: 0.3132321835, green: 0.3215333223, blue: 0.3312986195, alpha: 1)), Color(#colorLiteral(red: 0.2587893307, green: 0.2493893802, blue: 0.244140774, alpha: 1)), Color(#colorLiteral(red: 0.2634277046, green: 0.2641600966, blue: 0.2641601264, alpha: 1)), Color(#colorLiteral(red: 0.2841788828, green: 0.3059085011, blue: 0.3618154526, alpha: 1)), Color(#colorLiteral(red: 0.2055648863, green: 0.2585456371, blue: 0.2976065278, alpha: 1)), Color(#colorLiteral(red: 0.4104003906, green: 0.4125977159, blue: 0.4106445312, alpha: 1)), Color(#colorLiteral(red: 0.1389164627, green: 0.117431201, blue: 0.1096194014, alpha: 1)), Color(#colorLiteral(red: 0.1121824756, green: 0.1110228971, blue: 0.1369624734, alpha: 1)), Color(#colorLiteral(red: 0.1311036646, green: 0.1232908443, blue: 0.1350096166, alpha: 1)), Color(#colorLiteral(red: 0.2658690214, green: 0.2680663466, blue: 0.2666015625, alpha: 1)), Color(#colorLiteral(red: 0.08612059802, green: 0.08807375282, blue: 0.08026132733, alpha: 1)), Color(#colorLiteral(red: 0.1252442002, green: 0.1267089546, blue: 0.1252441704, alpha: 1))
    ]
    
    var body: some View {
        AnimatedTabView(selection: $selectedTab) {
            Tab.init(AppTab.habits.title, systemImage: AppTab.habits.symbolImage, value: .habits) {
                NavigationStack {
                    HomeView(zoomNamespace: zoomNamespace, selectedDate: $selectedDate, selectedHabit: $selectedHabit)
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
            
            Tab.init(AppTab.search.title, systemImage: AppTab.search.symbolImage, value: .search, role: .search) {
                NavigationStack {
                    List {
                        
                    }
                    .navigationTitle("Search")
                    .searchable(text: $searchText, placement: .toolbar, prompt: Text("Search..."))
                }
            }
        } effects: { tab in
            switch tab {
            case .habits: [.bounce]
            case .tasks: [.bounce]
            case .settings: [.rotate]
            case .search: [.wiggle]
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .preferredColorScheme(themeMode.colorScheme)
        .tint(.mainApp)
        .fullScreenSheet(
            ignoresSafeArea: true,
            isPresented: Binding(
                get: { selectedHabit != nil },
                set: { if !$0 { selectedHabit = nil } }
            ),
            content: { safeArea in
                if let habit = selectedHabit {
                    HabitDetailView(habit: habit, date: selectedDate)
                        .safeAreaPadding(.top, safeArea.top)
                }
            },
            background: {
                ConcentricRectangle()
                    .fill(currentRandomColor.gradient)
            }
        )
        .onChange(of: selectedHabit) { _, newValue in
            if newValue != nil {
                let newColor = backgroundColors.filter { $0 != currentRandomColor }.randomElement()
                currentRandomColor = newColor ?? .mainBackground
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHabitFromDeeplink)) { notification in
            guard let habit = notification.object as? Habit else { return }
            
            selectedTab = .habits
            selectedHabit = habit
        }
    }
}

enum AppTab: AnimatedTabSelectionProtocol {
    case habits
    case tasks
    case settings
    case search
    
    var symbolImage: String {
        switch self {
        case .habits: return "checkmark.circle.dotted"
        case .tasks: return "checklist"
        case .settings: return "gearshape"
        case .search: return "magnifyingglass"
        }
    }
    
    var title: LocalizedStringResource {
        switch self {
        case .habits: return "tabview_habits"
        case .tasks: return "tabview_tasks"
        case .settings: return "tabview_settings"
        case .search: return "tabview_search"
        }
    }
}
