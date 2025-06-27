import SwiftUI

struct CardGradients {
    static let completionRate = [
        Color(#colorLiteral(red: 0.4901960784, green: 0.5607843137, blue: 0.6196078431, alpha: 1)),
        Color(#colorLiteral(red: 0.1215686275, green: 0.1568627451, blue: 0.2705882353, alpha: 1))
    ]
    
    static let activeDays = [
        Color(#colorLiteral(red: 0.9921568627, green: 0.4745098039, blue: 0.4352941176, alpha: 1)),
        Color(#colorLiteral(red: 0.7490196078, green: 0.262745098, blue: 0.2509803922, alpha: 1))
    ]
    
    static let habitsDone = [
        Color(#colorLiteral(red: 0.6588235294, green: 0.8784313725, blue: 0.3882352941, alpha: 1)),
        Color(#colorLiteral(red: 0.337254902, green: 0.6705882353, blue: 0.1843137255, alpha: 1))
    ]
    
    static let activeHabits = [
        Color(#colorLiteral(red: 0.4549019608, green: 0.6352941176, blue: 0.8823529412, alpha: 1)),
        Color(#colorLiteral(red: 0.5411764706, green: 0.3019607843, blue: 0.6352941176, alpha: 1))
    ]
    
    static func adaptive(_ colors: [Color], colorScheme: ColorScheme) -> [Color] {
            return colorScheme == .dark ? colors.reversed() : colors
        }
}

struct OverviewStatsView: View {
    let habits: [Habit]
    let timeRange: OverviewTimeRange
    
    @State private var statsData: MotivatingOverviewStats = MotivatingOverviewStats()
    @State private var selectedInfoCard: InfoCard? = nil
    @ObservedObject private var colorManager = AppColorManager.shared
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header - clean без фона
            VStack(alignment: .leading, spacing: 8) {
                Text(headerTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            
            // ✅ Stats Grid - новые градиентные карточки с 3D иконками
            LazyVGrid(columns: gridColumns, spacing: 16) {
                // 1. Completion Rate
                StatCardInteractive(
                    title: "completion_rate".localized,
                    value: "\(Int(statsData.completionRate * 100))%",
                    onTap: { selectedInfoCard = .completionRate },
                    gradientColors: CardGradients.completionRate,
                    icon3DAsset: "CardInfo_completion_rate",
                    iconSize: 46
                )
                // 2. Active Days
                StatCardInteractive(
                    title: "active_days".localized,
                    value: activeDaysDisplayValue,
                    onTap: { selectedInfoCard = .activeDays },
                    gradientColors: CardGradients.activeDays,
                    icon3DAsset: "CardInfo_active_days"
                )
                
                // 3. Habits Done
                StatCardInteractive(
                    title: "habits_done".localized,
                    value: "\(statsData.habitsCompleted)",
                    onTap: { selectedInfoCard = .habitsDone },
                    gradientColors: CardGradients.habitsDone,
                    icon3DAsset: "CardInfo_habits_done"
                )
                // 4. Active Habits
                StatCardInteractive(
                    title: "active_habits".localized,
                    value: "\(statsData.activeHabitsCount)",
                    onTap: { selectedInfoCard = .activeHabits },
                    gradientColors: CardGradients.activeHabits,
                    icon3DAsset: "CardInfo_active_habits"
                )
            }
            .padding(.horizontal, 16)
            
            // Divider для отделения от привычек
            Divider()
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 0)
        .onAppear {
            calculateStats()
        }
        .onChange(of: timeRange) { _, _ in
            calculateStats()
        }
        .onChange(of: habits.count) { _, _ in
            calculateStats()
        }
        .sheet(item: $selectedInfoCard) { card in
            CardInfoView(card: card, timeRange: timeRange)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Computed Properties
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 160), spacing: 16),
            GridItem(.adaptive(minimum: 160), spacing: 16)
        ]
    }
    
    // ✅ НОВОЕ: Active Days с отображением прогресса
    private var activeDaysDisplayValue: String {
        let activeDays = statsData.activeDays
        let totalDays = getTotalDaysInRange()
        return "\(activeDays)/\(totalDays)"
    }
    
    // ✅ Вычисляем общее количество дней в периоде
    private func getTotalDaysInRange() -> Int {

        switch timeRange {
        case .week:
            return 7
            
        case .month:
            return 30
            
        case .year:
            // ✅ ИСПРАВЛЕНИЕ: для Year всегда показываем 365 дней
            return 365
            
        case .heatmap:
            // Heatmap не использует Active Days карточку, но на всякий случай
            return 365
        }
    }
    
    private var headerTitle: String {
        switch timeRange {
        case .week: return "last_7_days".localized
        case .month: return "last_30_days".localized
        case .year: return "last_12_months".localized
        case .heatmap: return "activity_overview".localized
        }
    }
    
    private var headerSubtitle: String {
        let formatter = DateFormatter()
        let today = Date()
        
        switch timeRange {
        case .week:
            let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: weekStart)
            let endString = formatter.string(from: today)
            return "\(startString) - \(endString)"
            
        case .month:
            let monthStart = calendar.date(byAdding: .day, value: -29, to: today) ?? today
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: monthStart)
            let endString = formatter.string(from: today)
            return "\(startString) - \(endString)"
            
        case .year:
            let yearStart = calendar.date(byAdding: .month, value: -11, to: today) ?? today
            formatter.dateFormat = "MMM yyyy"
            let startString = formatter.string(from: yearStart)
            let endString = formatter.string(from: today)
            return "\(startString) - \(endString)"
            
        case .heatmap:
            return "past_365_days".localized
        }
    }
    
    // MARK: - Stats Calculation
    
    private func calculateStats() {
        let now = Date()
        let dateRange = getDateRange(for: timeRange, from: now)
        
        let habitsCompleted = calculateHabitsCompleted(in: dateRange)
        let activeDays = calculateActiveDays(in: dateRange)
        let completionRate = calculateCompletionRate(in: dateRange)
        let activeHabitsCount = habits.filter { !$0.isArchived }.count
        
        statsData = MotivatingOverviewStats(
            habitsCompleted: habitsCompleted,
            activeDays: activeDays,
            completionRate: completionRate,
            activeHabitsCount: activeHabitsCount
        )
    }
    
    private func getDateRange(for timeRange: OverviewTimeRange, from date: Date) -> (start: Date, end: Date) {
        switch timeRange {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: date) ?? date
            return (start, date)
            
        case .month:
            let start = calendar.date(byAdding: .day, value: -29, to: date) ?? date
            return (start, date)
            
        case .year:
            let start = calendar.date(byAdding: .month, value: -11, to: date) ?? date
            return (start, date)
            
        case .heatmap:
            let start = calendar.date(byAdding: .day, value: -364, to: date) ?? date
            return (start, date)
        }
    }
    
    // MARK: - Individual Calculations
    
    private func calculateHabitsCompleted(in dateRange: (start: Date, end: Date)) -> Int {
        var completed = 0
        
        for habit in habits {
            var currentDate = dateRange.start
            while currentDate <= min(dateRange.end, Date()) {
                if habit.isActiveOnDate(currentDate) && habit.progressForDate(currentDate) >= habit.goal {
                    completed += 1
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        return completed
    }
    
    private func calculateActiveDays(in dateRange: (start: Date, end: Date)) -> Int {
        var activeDaysSet: Set<String> = []
        
        var currentDate = dateRange.start
        while currentDate <= min(dateRange.end, Date()) {
            
            let hasAnyProgress = habits.contains { habit in
                habit.isActiveOnDate(currentDate) && habit.progressForDate(currentDate) > 0
            }
            
            if hasAnyProgress {
                let dayKey = "\(calendar.component(.year, from: currentDate))-\(calendar.component(.month, from: currentDate))-\(calendar.component(.day, from: currentDate))"
                activeDaysSet.insert(dayKey)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return activeDaysSet.count
    }
    
    private func calculateCompletionRate(in dateRange: (start: Date, end: Date)) -> Double {
        var totalProgress = 0.0
        var totalPossibleProgress = 0.0
        
        for habit in habits.filter({ !$0.isArchived }) {
            var currentDate = dateRange.start
            while currentDate <= min(dateRange.end, Date()) {
                if habit.isActiveOnDate(currentDate) {
                    let progress = habit.progressForDate(currentDate)
                    let goal = habit.goal
                    
                    if goal > 0 {
                        totalProgress += min(Double(progress), Double(goal)) // Cap at goal to avoid over 100%
                        totalPossibleProgress += Double(goal)
                    }
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        return totalPossibleProgress > 0 ? totalProgress / totalPossibleProgress : 0.0
    }
}

// MARK: - Supporting Models

struct MotivatingOverviewStats {
    let habitsCompleted: Int          // Number of completed habits (any progress >= goal)
    let activeDays: Int               // Days with at least one action
    let completionRate: Double        // Average completion rate (0.0 to 1.0)
    let activeHabitsCount: Int        // Number of non-archived habits
    
    init(habitsCompleted: Int = 0, activeDays: Int = 0, completionRate: Double = 0.0, activeHabitsCount: Int = 0) {
        self.habitsCompleted = habitsCompleted
        self.activeDays = activeDays
        self.completionRate = completionRate
        self.activeHabitsCount = activeHabitsCount
    }
}

// MARK: - Info Models

enum InfoCard: String, Identifiable {
    case habitsDone = "habits_done"
    case activeDays = "active_days"
    case completionRate = "completion_rate"
    case activeHabits = "active_habits"
    
    var id: String { rawValue }
}

// MARK: - StatCardInteractive (✅ ОБНОВЛЕННАЯ ВЕРСИЯ)

struct StatCardInteractive: View {
    let title: String
    let value: String
    let onTap: () -> Void
    let gradientColors: [Color]
    let icon3DAsset: String
    let iconSize: CGFloat
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    private static let defaultIconSize: CGFloat = 40
    
    init(
        title: String,
        value: String,
        onTap: @escaping () -> Void,
        gradientColors: [Color],
        icon3DAsset: String,
        iconSize: CGFloat = StatCardInteractive.defaultIconSize
    ) {
        self.title = title
        self.value = value
        self.onTap = onTap
        self.gradientColors = gradientColors
        self.icon3DAsset = icon3DAsset
        self.iconSize = iconSize
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .padding(.top, 8)
                    .padding(.horizontal, 12)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                
                
                Spacer(minLength: 8)
                
                HStack(spacing: 12) {
                    // ✅ 3D Иконка
                    Image(icon3DAsset)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
            .frame(height: 120)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: CardGradients.adaptive(gradientColors, colorScheme: colorScheme),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .background(cardShadow)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        Color.gray.opacity(0.2),
                        lineWidth: 0.7
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: isPressed)
            .hapticFeedback(.impact(weight: .light), trigger: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
    
    private var cardShadow: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.clear)
            .shadow(
                color: Color.primary.opacity(0.2),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Info Views

struct CardInfoView: View {
    let card: InfoCard
    let timeRange: OverviewTimeRange
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        Image(cardIllustration)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: cardImageSize.width, height: cardImageSize.height)
                        Spacer()
                    }
                    .padding(.top, 0)
                    .padding(.bottom, 20)
                    
                    // Контент с отступами
                    VStack(alignment: .leading, spacing: 24) {
                        // Card description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("what_it_shows".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(cardDescription)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        
                        // How it's calculated
                        VStack(alignment: .leading, spacing: 8) {
                            Text("how_its_calculated".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(calculationDescription)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Example
                        VStack(alignment: .leading, spacing: 8) {
                            Text("example".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(exampleDescription)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle(cardTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("button_done".localized) {
                        dismiss()
                    }
                    .foregroundStyle(cardColor)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var cardIllustration: String {
        switch card {
        case .habitsDone: return "CardInfo_habits_done"
        case .activeDays: return "CardInfo_active_days"
        case .completionRate: return "CardInfo_completion_rate"
        case .activeHabits: return "CardInfo_active_habits"
        }
    }
    
    private var cardImageSize: CGSize {
        // Единый размер для всех карточек
        return CGSize(width: 200, height: 160)
    }
    
    private var cardColor: Color {
        let gradients = gradientForCard(card)
        return colorScheme == .dark ? gradients[0] : gradients[1]  // Светлый для темной темы, темный для светлой
    }
    
    private func gradientForCard(_ card: InfoCard) -> [Color] {
        switch card {
        case .completionRate: return CardGradients.completionRate
        case .activeDays: return CardGradients.activeDays
        case .habitsDone: return CardGradients.habitsDone
        case .activeHabits: return CardGradients.activeHabits
        }
    }
    
    private var cardTitle: String {
        switch card {
        case .habitsDone: return "habits_done".localized
        case .activeDays: return "active_days".localized
        case .completionRate: return "completion_rate".localized
        case .activeHabits: return "active_habits".localized
        }
    }
    
    private var cardDescription: String {
        switch card {
        case .habitsDone:
            return "habits_done_description".localized
        case .activeDays:
            return "active_days_description".localized
        case .completionRate:
            return "completion_rate_description".localized
        case .activeHabits:
            return "active_habits_description".localized
        }
    }
    
    private var calculationDescription: String {
        switch card {
        case .habitsDone:
            return "habits_done_calculation".localized
        case .activeDays:
            return "active_days_calculation".localized
        case .completionRate:
            return "completion_rate_calculation".localized
        case .activeHabits:
            return "active_habits_calculation".localized
        }
    }
    
    private var exampleDescription: String {
        switch card {
        case .habitsDone:
            return "habits_done_example".localized
        case .activeDays:
            return "active_days_example".localized
        case .completionRate:
            return "completion_rate_example".localized
        case .activeHabits:
            return "active_habits_example".localized
        }
    }
}
