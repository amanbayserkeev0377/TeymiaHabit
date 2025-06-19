import SwiftUI

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
            
            // Stats Grid - новый порядок карточек
            LazyVGrid(columns: gridColumns, spacing: 16) {
                // 1. Active Habits (первая)
                StatCardInteractive(
                    title: "active_habits".localized, 
                    value: "\(statsData.activeHabitsCount)",
                    icon: "list.bullet.rectangle.fill",
                    color: Color(#colorLiteral(red: 1, green: 0.6156862745, blue: 0.4549019608, alpha: 1)),
                    onTap: { selectedInfoCard = .activeHabits }
                )
                
                // 2. Active Days (вторая)
                StatCardInteractive(
                    title: "active_days".localized,
                    value: "\(statsData.activeDays)",
                    icon: "calendar.badge.checkmark",
                    color: Color(#colorLiteral(red: 0.5960784314, green: 0.2745098039, blue: 0.4039215686, alpha: 1)),
                    onTap: { selectedInfoCard = .activeDays }
                )
                
                // 3. Habits Done (третья)
                StatCardInteractive(
                    title: "habits_done".localized,
                    value: "\(statsData.habitsCompleted)",
                    icon: "checkmark.circle.fill",
                    color: Color(#colorLiteral(red: 0.5725490196, green: 0.7490196078, blue: 0.4235294118, alpha: 1)),
                    onTap: { selectedInfoCard = .habitsDone }
                )
                
                // 4. Completion Rate (четвертая)
                StatCardInteractive(
                    title: "completion_rate".localized,
                    value: "\(Int(statsData.completionRate * 100))%",
                    icon: "chart.pie.fill",
                    color: Color(#colorLiteral(red: 0.3843137255, green: 0.5215686275, blue: 0.662745098, alpha: 1)),
                    onTap: { selectedInfoCard = .completionRate }
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

// MARK: - StatCardInteractive

struct StatCardInteractive: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .padding(.top, 14)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: 140) // ✅ ФИКСИРОВАННАЯ ширина = естественные переносы
                    .frame(maxWidth: .infinity) // ✅ Но карточка полной ширины
                
                
                Spacer(minLength: 8)
                
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(color)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
            .frame(minHeight: 105)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.2))
            }
            .background(cardShadow)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
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
    
    // MARK: - Computed Properties
    
    private var strokeColor: Color {
        if isPressed {
            return color.opacity(0.5) // При нажатии - более яркий stroke
        } else {
            return Color(.separator).opacity(0.3) // Обычное состояние - тонкий stroke
        }
    }
    
    private var strokeWidth: CGFloat {
        isPressed ? 1.5 : 0.5 // Тонкий stroke в обычном состоянии
    }
    
    private var cardShadow: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.clear)
            .shadow(
                color: Color.black.opacity(isPressed ? 0.15 : 0.08), // Легкая тень
                radius: isPressed ? 6 : 3,
                x: 0,
                y: isPressed ? 3 : 1.5
            )
    }
}

// MARK: - Info Views

struct CardInfoView: View {
    let card: InfoCard
    let timeRange: OverviewTimeRange
    @Environment(\.dismiss) private var dismiss
    
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
        switch card {
        case .habitsDone: 
            return Color(#colorLiteral(red: 0.5725490196, green: 0.7490196078, blue: 0.4235294118, alpha: 1))
        case .activeDays: 
            return Color(#colorLiteral(red: 0.5960784314, green: 0.2745098039, blue: 0.4039215686, alpha: 1))
        case .completionRate: 
            return Color(#colorLiteral(red: 0.3843137255, green: 0.5215686275, blue: 0.662745098, alpha: 1))
        case .activeHabits: 
            return Color(#colorLiteral(red: 1, green: 0.6156862745, blue: 0.4549019608, alpha: 1))
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
