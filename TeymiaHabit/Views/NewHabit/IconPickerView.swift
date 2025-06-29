import SwiftUI

struct IconPickerView: View {
    // MARK: - Bindings
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject private var colorManager = AppColorManager.shared
    
    // MARK: - Constants
    private let defaultIcon = "checkmark"
    
    // MARK: - Adaptive Properties
    
    /// Icon size based on device and dynamic type
    private var iconSize: CGFloat {
        let baseSize: CGFloat = horizontalSizeClass == .compact ? 36 : 42
        let typeMultiplier = dynamicTypeMultiplier
        return baseSize * typeMultiplier
    }
    
    /// Button size based on device and dynamic type
    private var buttonSize: CGFloat {
        let baseSize: CGFloat = horizontalSizeClass == .compact ? 60 : 70
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
    private func isSelected(_ iconName: String) -> Bool {
        return selectedIcon == iconName
    }
    
    // MARK: - Data
    
    private let categories: [IconCategory] = [
        IconCategory(name: "health".localized, icons: [
            "figure.walk", "figure.run", "figure.stairs", "figure.strengthtraining.traditional", "figure.cooldown",
            "figure.mind.and.body", "figure.pool.swim", "shoeprints.fill", "bicycle", "bed.double.fill",
            "brain.fill", "eye.fill", "heart.fill", "lungs.fill", "waterbottle.fill",
            "pills.fill", "testtube.2", "stethoscope", "carrot.fill", "tree.fill"
        ]),
        
        IconCategory(name: "productivity".localized, icons: [
            "brain.head.profile.fill", "clock.fill", "hourglass", "pencil.and.list.clipboard", "pencil.and.scribble",
            "book.fill", "graduationcap.fill", "translate", "function", "chart.pie.fill",
            "checklist", "calendar.badge.clock", "person.2.wave.2.fill", "bubble.left.and.bubble.right.fill", "globe.americas.fill",
            "medal.fill", "macbook", "keyboard.fill", "lightbulb.max.fill", "atom"
        ]),
        
        IconCategory(name: "hobbies".localized, icons: [
            "camera.fill", "play.rectangle.fill", "headphones", "music.note", "film.fill",
            "paintbrush.pointed.fill", "paintpalette.fill", "photo.fill", "theatermasks.fill", "puzzlepiece.extension.fill",
            "pianokeys", "guitars.fill", "rectangle.pattern.checkered", "mountain.2.fill", "drone.fill",
            "playstation.logo", "xbox.logo", "formfitting.gamecontroller.fill", "motorcycle.fill", "scooter",
            "soccerball", "basketball.fill", "volleyball.fill", "tennisball.fill", "tennis.racket"
        ]),
        
        IconCategory(name: "lifestyle".localized, icons: [
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
                        // Section header
                        Text(category.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)
                        
                        // Icons grid
                        LazyVGrid(columns: adaptiveColumns, spacing: 12) {
                            ForEach(category.icons, id: \.self) { iconName in
                                iconButton(for: iconName, in: category)
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
    
    /// Individual icon button
    private func iconButton(for iconName: String, in category: IconCategory) -> some View {
        let isSelected = isSelected(iconName)
        
        return Button {
            selectedIcon = iconName
            HapticManager.shared.playSelection()
        } label: {
            VStack {
                iconImage(for: iconName, isSelected: isSelected)
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(
                Circle()
                    .fill(
                        // ✅ ИСПРАВЛЕНО: только выбранная иконка получает градиент
                        isSelected
                        ? selectedColor.adaptiveGradient(
                            for: colorScheme,
                            lightOpacity: 0.8,
                            darkOpacity: 1.0
                        )
                        : LinearGradient(
                            colors: colorScheme == .dark
                            ? [Color(.systemGray4), Color(.systemGray6)]  // Серый градиент для темной темы
                            : [Color(.systemGray6), Color(.systemGray4)], // Серый градиент для светлой темы
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.easeInOut(duration: 0.25), value: selectedColor)
        }
        .buttonStyle(.plain)
    }
    
    /// Icon image with proper color logic
    private func iconImage(for iconName: String, isSelected: Bool) -> some View {
        Image(systemName: iconName)
            .font(.system(size: iconSize * 0.65, weight: .medium))
            .frame(width: iconSize * 0.8, height: iconSize * 0.8)
            .foregroundStyle(
                isSelected ? .white : .secondary
            )
    }
}

// MARK: - Icon Category Model

struct IconCategory {
    let name: String
    let icons: [String]
    let isCustom: Bool
    
    init(name: String, icons: [String], isCustom: Bool = false) {
        self.name = name
        self.icons = icons
        self.isCustom = isCustom
    }
}
