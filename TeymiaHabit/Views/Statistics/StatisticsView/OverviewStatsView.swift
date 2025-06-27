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
        Color(#colorLiteral(red: 0.5215686275, green: 0.8, blue: 0, alpha: 1)),
        Color(#colorLiteral(red: 0.337254902, green: 0.6705882353, blue: 0.1843137255, alpha: 1))
    ]
    
    static let activeHabits = [
        Color(#colorLiteral(red: 0.431372549, green: 0.6941176471, blue: 0.8392156863, alpha: 1)),
        Color(#colorLiteral(red: 0.2156862745, green: 0.462745098, blue: 0.631372549, alpha: 1))
    ]
    
    static func adaptive(_ colors: [Color], colorScheme: ColorScheme) -> [Color] {
            return colorScheme == .dark ? colors.reversed() : colors
        }
}

struct OverviewStatsView: View {
    let habits: [Habit]
    
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
                Text("overview".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("your_total_progress".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            
            // ✅ Stats Grid - новые градиентные карточки с 3D иконками
            LazyVGrid(columns: gridColumns, spacing: 16) {
                // 1. Completion Rate
                StatCardInteractive(
                    title: "overall_completion".localized,
                    value: "\(Int(overallCompletionRate * 100))%",
                    onTap: { selectedInfoCard = .completionRate },
                    gradientColors: CardGradients.completionRate,
                    icon3DAsset: "CardInfo_completion_rate",
                    iconSize: 46
                )
                // 2. Active Days
                StatCardInteractive(
                    title: "active_days_total".localized,
                    value: "\(totalActiveDays)",
                    onTap: { selectedInfoCard = .activeDays },
                    gradientColors: CardGradients.activeDays,
                    icon3DAsset: "CardInfo_active_days"
                )
                
                // 3. Habits Done
                StatCardInteractive(
                    title: "completed_total".localized,
                    value: "\(totalCompletedHabits)",
                    onTap: { selectedInfoCard = .habitsDone },
                    gradientColors: CardGradients.habitsDone,
                    icon3DAsset: "CardInfo_habits_done"
                )
                // 4. Active Habits
                StatCardInteractive(
                    title: "active_habits".localized,
                    value: "\(activeHabitsCount)",
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
        .sheet(item: $selectedInfoCard) { card in
            CardInfoView(card: card)
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
    
    // ДОБАВИТЬ эти простые computed properties:
    private var totalCompletedHabits: Int {
        habits.reduce(0) { total, habit in
            total + (habit.completions?.filter { $0.value >= habit.goal }.count ?? 0)
        }
    }

    private var totalActiveDays: Int {
        var activeDaysSet: Set<String> = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for habit in habits {
            guard let completions = habit.completions else { continue }
            
            for completion in completions {
                if completion.value > 0 && habit.isActiveOnDate(completion.date) {
                    let dateKey = dateFormatter.string(from: completion.date)
                    activeDaysSet.insert(dateKey)
                }
            }
        }
        
        return activeDaysSet.count
    }

    private var overallCompletionRate: Double {
        var totalProgress = 0.0
        var totalPossibleProgress = 0.0
        
        for habit in habits.filter({ !$0.isArchived }) {
            guard let completions = habit.completions else { continue }
            
            for completion in completions {
                if habit.isActiveOnDate(completion.date) {
                    let progress = completion.value
                    let goal = habit.goal
                    
                    if goal > 0 {
                        totalProgress += min(Double(progress), Double(goal))
                        totalPossibleProgress += Double(goal)
                    }
                }
            }
        }
        
        return totalPossibleProgress > 0 ? totalProgress / totalPossibleProgress : 0.0
    }

    private var activeHabitsCount: Int {
        habits.filter { !$0.isArchived }.count
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
    case habitsDone = "overall_completion"
    case activeDays = "active_days_total"
    case completionRate = "completed_total"
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
        return colorScheme == .dark ? gradients[0] : gradients[1]
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
        case .habitsDone: return "completed_total".localized
        case .activeDays: return "active_days_total".localized
        case .completionRate: return "overall_completion".localized
        case .activeHabits: return "active_habits".localized
        }
    }

    private var cardDescription: String {
        switch card {
        case .habitsDone:
            return "completed_total_description".localized
        case .activeDays:
            return "active_days_total_description".localized
        case .completionRate:
            return "overall_completion_description".localized
        case .activeHabits:
            return "active_habits_description".localized
        }
    }

    private var calculationDescription: String {
        switch card {
        case .habitsDone:
            return "completed_total_calculation".localized
        case .activeDays:
            return "active_days_total_calculation".localized
        case .completionRate:
            return "overall_completion_calculation".localized
        case .activeHabits:
            return "active_habits_calculation".localized
        }
    }

    private var exampleDescription: String {
        switch card {
        case .habitsDone:
            return "completed_total_example".localized
        case .activeDays:
            return "active_days_total_example".localized
        case .completionRate:
            return "overall_completion_example".localized
        case .activeHabits:
            return "active_habits_example".localized
        }
    }
}
