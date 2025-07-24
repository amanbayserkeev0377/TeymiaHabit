import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Provider
struct HabitWidgetTimelineProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> HabitWidgetEntry {
        return HabitWidgetEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> ()) {
        let entry = getCurrentEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> ()) {
        let currentEntry = getCurrentEntry()
        
        // Простая стратегия: обновляем в полночь
        let nextMidnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        
        let timeline = Timeline(
            entries: [currentEntry],
            policy: .after(nextMidnight)
        )
        
        completion(timeline)
    }
    
    private func getCurrentEntry() -> HabitWidgetEntry {
        let today = Date()
        let activeHabits = fetchActiveHabits(for: today)
        
        let habitData = activeHabits.map { habit in
            HabitWidgetData(from: habit, date: today)
        }
        
        return HabitWidgetEntry(date: today, habits: habitData)
    }
    
    // Прямо здесь получаем данные (без отдельного WidgetDataProvider)
    private func fetchActiveHabits(for date: Date) -> [Habit] {
        let appGroupId = "group.com.amanbayserkeev.teymiahabit"
        let schema = Schema([Habit.self, HabitCompletion.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(appGroupId),
            cloudKitDatabase: .none // Важно: отключаем CloudKit
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(container)
            
            let request = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { habit in
                    !habit.isArchived
                },
                sortBy: [SortDescriptor(\Habit.displayOrder)]
            )
            
            let allHabits = try context.fetch(request)
            let activeHabits = allHabits.filter { habit in
                habit.isActiveOnDate(date)
            }
            
            print("📊 Widget fetched \(activeHabits.count) active habits")
            return activeHabits
            
        } catch {
            print("❌ Widget data fetch error: \(error)")
            return []
        }
    }
}

// MARK: - Widget Entry
struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let habits: [HabitWidgetData]
    
    static let placeholder = HabitWidgetEntry(
        date: Date(),
        habits: Array(repeating: HabitWidgetData.placeholder, count: 4)
    )
}

// MARK: - Habit Widget Data
struct HabitWidgetData: Identifiable {
    let id: UUID
    let title: String
    let iconName: String?
    let iconColor: HabitIconColor
    let progress: Double
    let currentValue: Int
    let goal: Int
    let isCompleted: Bool
    let isExceeded: Bool
    let type: HabitType
    
    // Основной инициализатор из Habit
    init(from habit: Habit, date: Date = Date()) {
        self.id = habit.uuid
        self.title = habit.title
        self.iconName = habit.iconName
        self.iconColor = habit.iconColor
        self.goal = habit.goal
        self.type = habit.type
        
        // Получаем прогресс за указанную дату
        self.currentValue = habit.progressForDate(date)
        
        // Вычисляем процент выполнения
        if goal > 0 {
            self.progress = min(Double(currentValue) / Double(goal), 1.0)
        } else {
            self.progress = 0.0
        }
        
        self.isCompleted = currentValue >= goal && goal > 0
        self.isExceeded = currentValue > goal && goal > 0
    }
    
    // Дополнительный инициализатор для placeholder
    init(id: UUID, title: String, iconName: String?, iconColor: HabitIconColor, progress: Double, currentValue: Int, goal: Int, isCompleted: Bool, isExceeded: Bool, type: HabitType) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.iconColor = iconColor
        self.progress = progress
        self.currentValue = currentValue
        self.goal = goal
        self.isCompleted = isCompleted
        self.isExceeded = isExceeded
        self.type = type
    }
    
    static let placeholder = HabitWidgetData(
        id: UUID(),
        title: "Sample Habit",
        iconName: "checkmark",
        iconColor: HabitIconColor.primary,
        progress: 0.7,
        currentValue: 7,
        goal: 10,
        isCompleted: false,
        isExceeded: false,
        type: HabitType.count
    )
}

// MARK: - Mini Widget (2x2)
struct HabitMiniWidget: Widget {
    let kind: String = "HabitMiniWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitWidgetTimelineProvider()) { entry in
            HabitMiniWidgetView(entry: entry)
                .containerBackground(Color(.systemBackground), for: .widget)
        }
        .configurationDisplayName("widget_title".localized)
        .description("widget_description".localized)
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Grid Widget (4x2)
struct HabitGridWidget: Widget {
    let kind: String = "HabitGridWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitWidgetTimelineProvider()) { entry in
            HabitGridWidgetView(entry: entry)
                .containerBackground(Color(.systemBackground), for: .widget)
        }
        .configurationDisplayName("widget_title".localized)
        .description("widget_description".localized)
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Mini Widget View (2x2)
struct HabitMiniWidgetView: View {
    let entry: HabitWidgetEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if entry.habits.isEmpty {
            EmptyWidgetView(message: "widget_no_active_habits_today".localized)
        } else {
            VStack(spacing: 16) { // Фиксированный spacing между строками
                // Первая строка (позиции 0 и 1)
                HStack(spacing: 16) { // Фиксированный spacing между колонками
                    // Позиция [0,0] - первая привычка или пустое место
                    if entry.habits.count > 0 {
                        HabitRingCell(habit: entry.habits[0], size: 60)
                    } else {
                        Color.clear
                            .frame(width: 60, height: 60)
                    }
                    
                    // Позиция [0,1] - вторая привычка или пустое место
                    if entry.habits.count > 1 {
                        HabitRingCell(habit: entry.habits[1], size: 60)
                    } else {
                        Color.clear
                            .frame(width: 60, height: 60)
                    }
                }
                
                // Вторая строка (позиции 2 и 3)
                HStack(spacing: 16) { // Фиксированный spacing между колонками
                    // Позиция [1,0] - третья привычка или пустое место
                    if entry.habits.count > 2 {
                        HabitRingCell(habit: entry.habits[2], size: 60)
                    } else {
                        Color.clear
                            .frame(width: 60, height: 60)
                    }
                    
                    // Позиция [1,1] - четвертая привычка или пустое место
                    if entry.habits.count > 3 {
                        HabitRingCell(habit: entry.habits[3], size: 60)
                    } else {
                        Color.clear
                            .frame(width: 60, height: 60)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)
        }
    }
}

// MARK: - Grid Widget View (4x2)
struct HabitGridWidgetView: View {
    let entry: HabitWidgetEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if entry.habits.isEmpty {
            EmptyWidgetView(message: "widget_no_active_habits_today".localized)
        } else {
            VStack(spacing: 20) {
                HStack(spacing: 24) {
                    ForEach(0..<4, id: \.self) { index in
                        if index < entry.habits.count {
                            HabitRingCell(habit: entry.habits[index], size: 60) // Используем тот же размер
                        } else {
                            Color.clear
                                .frame(width: 60, height: 60) // Обновили размер
                        }
                    }
                }
                HStack(spacing: 24) {
                    ForEach(4..<8, id: \.self) { index in
                        if index < entry.habits.count {
                            HabitRingCell(habit: entry.habits[index], size: 60) // Используем тот же размер
                        } else {
                            Color.clear
                                .frame(width: 60, height: 60) // Обновили размер
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)
        }
    }
}

// MARK: - Habit Ring Cell
struct HabitRingCell: View {
    let habit: HabitWidgetData
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 6.0)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: habit.progress)
                .stroke(
                    LinearGradient(
                        colors: ringColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 6.0,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
            
            // ✅ Используем готовый universalIcon extension
            EmptyView()
                .universalIcon(
                    iconId: habit.iconName,
                    baseSize: size * 0.40,
                    color: habit.iconColor,
                    colorScheme: colorScheme
                )
        }
        .frame(width: size, height: size)
    }
    
    private var ringColors: [Color] {
        return AppColorManager.getRingColors(  // <- Статический метод
            habitColor: habit.iconColor,
            isCompleted: habit.isCompleted,
            isExceeded: habit.isExceeded,
            colorScheme: colorScheme
        )
    }
}

// MARK: - Empty Widget View
struct EmptyWidgetView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.dashed")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "teymiahabit://")!)
    }
}
