import SwiftUI

// MARK: - Enum для типов иконок
enum IconType: Hashable {
    case sfSymbol(String)
    case image(String)
    
    var id: String {
        switch self {
        case .sfSymbol(let name): return "sf_\(name)"
        case .image(let name): return "img_\(name)"
        }
    }
}

// MARK: - Обновленная модель с Pro поддержкой
struct IconCategory {
    let name: String
    let icons: [IconType]
    let isPro: Bool
    
    // Инициализатор для SF Symbols
    init(name: String, sfSymbols: [String], isPro: Bool = false) {
        self.name = name
        self.icons = sfSymbols.map { .sfSymbol($0) }
        self.isPro = isPro
    }
    
    // Инициализатор для изображений
    init(name: String, images: [String], isPro: Bool = false) {
        self.name = name
        self.icons = images.map { .image($0) }
        self.isPro = isPro
    }
}

struct IconPickerView: View {
    // MARK: - Bindings
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(ProManager.self) private var proManager
    @ObservedObject private var colorManager = AppColorManager.shared
    
    // MARK: - State
    @State private var showingPaywall = false
    
    // MARK: - Constants
    private let defaultIcon = "checkmark"
    
    // MARK: - Adaptive Properties
    
    /// Icon size based on device and dynamic type
    private var iconSize: CGFloat {
        let baseSize: CGFloat = horizontalSizeClass == .compact ? 40 : 46
        let typeMultiplier = dynamicTypeMultiplier
        return baseSize * typeMultiplier
    }
    
    /// Button size based on device and dynamic type
    private var buttonSize: CGFloat {
        let baseSize: CGFloat = horizontalSizeClass == .compact ? 66 : 76
        let typeMultiplier = dynamicTypeMultiplier
        return baseSize * typeMultiplier
    }
    
    /// 3D Image size - больше чем обычные иконки
    private var imageSize: CGFloat {
        let baseSize: CGFloat = horizontalSizeClass == .compact ? 50 : 58
        let typeMultiplier = dynamicTypeMultiplier
        return baseSize * typeMultiplier
    }
    
    /// Dynamic type multiplier for accessibility
    private var dynamicTypeMultiplier: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5: return 1.4
        case .accessibility4: return 1.3
        case .accessibility3: return 1.2
        case .accessibility2, .accessibility1: return 1.1
        case .xxLarge, .xxxLarge: return 1.05
        default: return 1.0
        }
    }
    
    /// Adaptive grid columns
    private var adaptiveColumns: [GridItem] {
        let baseColumnCount = horizontalSizeClass == .compact ? 5 : 8
        // Reduce columns for larger dynamic type
        let adjustedCount = dynamicTypeSize.isAccessibilitySize ? max(3, baseColumnCount - 2) : baseColumnCount
        return Array(repeating: GridItem(.flexible()), count: adjustedCount)
    }
    
    // MARK: - Selection Logic
    
    /// Check if icon is selected
    private func isSelected(_ iconType: IconType) -> Bool {
        return selectedIcon == iconType.id
    }
    
    // MARK: - Data
    
    private let categories: [IconCategory] = [
        // 3D иконки ПЕРВЫМИ (Pro feature)
        IconCategory(name: "3D", images: [
            "3d_fitness_girl", "3d_fitness_girl2", "3d_fitness_girl3", "3d_fitness_boy", "3d_fitness_boy1", "3d_meditate_woman", "3d_meditate_woman2", "3d_meditate_man", "3d_shoe", "3d_swimming", "3d_basketball", "3d_football", "3d_water_lemon", "3d_tooth", "3d_cup", "3d_cooking", "3d_bulb", "3d_keyboard", "3d_hand_shaking", "3d_office", "3d_hand_smartphone", "3d_book", "3d_book_plant", "3d_forest", "3d_vegetable", "3d_sink", "3d_shower", "3d_bathroom", "3d_desk", "3d_graduate", "3d_graduationcap_books", "3d_graduationcap", "3d_coin_dollar", "3d_money", "3d_guitar", "3d_painting", "3d_wheel", "3d_youtube_button", "3d_insta"
        ], isPro: true),
        
        IconCategory(name: "health".localized, sfSymbols: [
            "figure.walk", "figure.run", "figure.stairs", "figure.strengthtraining.traditional", "figure.cooldown",
            "figure.mind.and.body", "figure.pool.swim", "shoeprints.fill", "bicycle", "bed.double.fill",
            "brain.fill", "eye.fill", "heart.fill", "lungs.fill", "waterbottle.fill",
            "pills.fill", "testtube.2", "stethoscope", "carrot.fill", "tree.fill"
        ]),
        
        IconCategory(name: "productivity".localized, sfSymbols: [
            "brain.head.profile.fill", "clock.fill", "hourglass", "pencil.and.list.clipboard", "pencil.and.scribble",
            "book.fill", "graduationcap.fill", "translate", "function", "chart.pie.fill",
            "checklist", "calendar.badge.clock", "person.2.wave.2.fill", "bubble.left.and.bubble.right.fill", "globe.americas.fill",
            "medal.fill", "macbook", "keyboard.fill", "lightbulb.max.fill", "atom"
        ]),
        
        IconCategory(name: "hobbies".localized, sfSymbols: [
            "camera.fill", "play.rectangle.fill", "headphones", "music.note", "film.fill",
            "paintbrush.pointed.fill", "paintpalette.fill", "photo.fill", "theatermasks.fill", "puzzlepiece.extension.fill",
            "pianokeys", "guitars.fill", "rectangle.pattern.checkered", "mountain.2.fill", "drone.fill",
            "playstation.logo", "xbox.logo", "formfitting.gamecontroller.fill", "motorcycle.fill", "scooter",
            "soccerball", "basketball.fill", "volleyball.fill", "tennisball.fill", "tennis.racket"
        ]),
        
        IconCategory(name: "lifestyle".localized, sfSymbols: [
            "shower.fill", "bathtub.fill", "sink.fill", "hands.and.sparkles.fill", "washer.fill",
            "fork.knife", "frying.pan.fill", "popcorn.fill", "cup.and.heat.waves.fill", "birthday.cake.fill",
            "cart.fill", "takeoutbag.and.cup.and.straw.fill", "gift.fill", "house.fill", "stroller.fill",
            "face.smiling.fill", "envelope.fill", "phone.fill", "beach.umbrella.fill", "pawprint.fill",
            "creditcard.fill", "banknote.fill", "location.fill", "hand.palm.facing.fill", "steeringwheel.and.hands"
        ])
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGroupedBackground)
                        .ignoresSafeArea()
            // Main content (Icon Grid)
            iconGridSection
                .safeAreaInset(edge: .bottom) {
                    // This creates space for the overlay
                    Color.clear.frame(height: 100)
                }
            
            // Overlay Color Picker Section (floating above)
            VStack(spacing: 16) {
                ColorPickerSection.forIconPicker(selectedColor: $selectedColor)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .primary.opacity(0.2), radius: 20, x: 0, y: -10)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("icon_and_color".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onAppear {
            if selectedIcon == nil {
                selectedIcon = defaultIcon
            }
        }
    }
    
    // MARK: - View Components
    
    /// Main icon grid section
    private var iconGridSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(categories, id: \.name) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        // Section header with Pro badge
                        HStack {
                            Text(category.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            if category.isPro && !proManager.isPro {
                                ProLockBadge()
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Icons grid
                        LazyVGrid(columns: adaptiveColumns, spacing: 12) {
                            ForEach(category.icons, id: \.id) { iconType in
                                iconButton(for: iconType, in: category)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Padding для floating color picker
                Color.clear.frame(height: 120)
            }
            .padding(.top, 16)
        }
    }
    
    @ViewBuilder
    private func iconImage(for iconType: IconType, isSelected: Bool) -> some View {
        switch iconType {
        case .sfSymbol(let name):
            Image(systemName: name)
                .font(.system(size: iconSize * 0.68, weight: .medium))
                .foregroundStyle(
                    isSelected
                    ? AnyShapeStyle(selectedColor.adaptiveGradient(for: colorScheme))
                    : AnyShapeStyle(
                        LinearGradient(
                            colors: [.gray.opacity(0.6), .gray],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                )
            
        case .image(let name):
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: imageSize, height: imageSize)
        }
    }
    
    // MARK: - Icon Button
    private func iconButton(for iconType: IconType, in category: IconCategory) -> some View {
        let isSelected = selectedIcon == iconType.id
        let isLocked = category.isPro && !proManager.isPro
        
        return Button {
            if isLocked {
                // Show paywall for Pro features
                showingPaywall = true
                return
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedIcon = iconType.id
            }
            HapticManager.shared.playSelection()
        } label: {
            iconImage(for: iconType, isSelected: isSelected)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            isSelected
                            ? AnyShapeStyle(selectedColor.adaptiveGradient(for: colorScheme).opacity(0.1))
                            : AnyShapeStyle(Color(UIColor.secondarySystemGroupedBackground))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            isSelected
                            ? selectedColor.color
                            : Color(.separator).opacity(0.5), // Тонкий серый для unselected
                            lineWidth: isSelected ? 1.0 : 0.7 // Чуть толще для selected
                        )
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Simplified version
extension View {
    @ViewBuilder
    func universalIcon(
        iconId: String?,
        baseSize: CGFloat,
        color: HabitIconColor,
        colorScheme: ColorScheme
    ) -> some View {
        let safeIconId = iconId ?? "checkmark"
        
        if safeIconId.hasPrefix("sf_") {
            let symbolName = String(safeIconId.dropFirst(3))
            Image(systemName: symbolName)
                .font(.system(size: baseSize, weight: .medium))
                .foregroundStyle(color.adaptiveGradient(for: colorScheme))
        } else if safeIconId.hasPrefix("img_") {
            let imageName = String(safeIconId.dropFirst(4))
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: baseSize * 1.6, height: baseSize * 1.6)
        } else {
            Image(systemName: safeIconId)
                .font(.system(size: baseSize, weight: .medium))
                .foregroundStyle(color.adaptiveGradient(for: colorScheme))
        }
    }
}
