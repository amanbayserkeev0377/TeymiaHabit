import SwiftUI

struct IconPickerView: View {
    
    // MARK: - Bindings
    @Binding var selectedIcon: String
    @Binding var selectedColor: HabitIconColor
    @Binding var hexColor: String?
    @State private var searchText: String = ""
    
    // MARK: - Layout Constants
    private enum Layout {
        static let circleSize: CGFloat = 44
        static let strokeWidth: CGFloat = 1.5
        static let selectedScale: CGFloat = 1.15
        static let gridSpacing: CGFloat = 14
        static let verticalPadding: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
    }
    
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Layout.gridSpacing), count: 6
    )
    
    // MARK: - Icons
    private let icons: [String] = [
        "figure.walk", "figure.walk.motion", "figure.run", "figure.badminton", "figure.baseball", "figure.basketball",
        "figure.bowling", "figure.boxing", "figure.cooldown", "figure.core.training", "figure.cricket", "figure.cross.training",
        "figure.dance", "figure.equestrian.sports", "figure.fishing", "figure.flexibility", "figure.strengthtraining.functional", "figure.golf",
        "figure.gymnastics", "figure.handball", "figure.highintensity.intervaltraining", "figure.hiking", "figure.hockey", "figure.jumprope",
        "figure.kickboxing", "figure.mind.and.body", "figure.mixed.cardio", "figure.outdoor.cycle", "figure.pickleball", "figure.pilates",
        "figure.play", "figure.pool.swim", "figure.rolling", "figure.indoor.rowing", "figure.rugby", "figure.indoor.soccer",
        "figure.socialdance", "figure.strengthtraining.traditional", "figure.volleyball", "figure.wrestling", "figure.yoga", "dumbbell.fill",
        "sportscourt.fill", "soccerball", "baseball.fill", "basketball.fill", "american.football.fill", "tennis.racket",
        "tennisball.fill", "volleyball.fill", "duffle.bag.fill", "trophy.fill", "medal.fill", "flag.pattern.checkered",
        "book.fill", "radicand.squareroot", "function", "brain.fill", "brain.head.profile.fill", "clock.fill",
        "hourglass", "command", "signature", "pencil", "scribble.variable", "apple.meditate",
        "bolt.fill", "flame.fill", "lightbulb.max.fill", "lamp.desk.fill", "person.fill", "person.2.fill",
        "person.line.dotted.person.fill", "person.3.fill", "person.bust.fill", "shoeprints.fill", "face.smiling.inverse", "eye.fill",
        "eyes.inverse", "eyebrow", "mouth.fill", "ear.fill", "hand.raised.palm.facing.fill", "hand.thumbsup.fill",
        "hands.and.sparkles.fill", "sink.fill", "toilet.fill", "stove.fill", "chair.lounge.fill", "sofa.fill",
        "bed.double.fill", "washer.fill", "popcorn.fill", "frying.pan.fill", "balloon.2.fill", "party.popper.fill",
        "bathtub.fill", "shower.handheld.fill", "shower.fill", "spigot.fill", "tray.and.arrow.down.fill", "text.document.fill",
        "list.bullet.clipboard.fill", "heart.fill", "heart.badge.bolt.fill", "facemask.fill", "lungs.fill", "syringe.fill",
        "pill.fill", "pills.fill", "play.rectangle.fill", "fleuron.fill", "sunrise.fill", "sun.horizon.fill",
        "dog.fill", "cat.fill", "pawprint.fill", "shield.fill", "shield.righthalf.filled", "lock.fill",
        "checkmark", "headset", "car.rear.fill", "car.fill", "motorcycle.fill", "fuelpump.fill",
        "lightrail.fill", "house.fill", "playstation.logo", "xbox.logo", "gamecontroller.fill", "formfitting.gamecontroller.fill",
        "camera.fill", "camera.macro", "photo.fill", "macbook", "iphone"
    ]
    
    private var filteredIcons: [String] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return icons }
        return icons.filter { $0.lowercased().contains(query) }
    }
    
    // Resolved active color for icon highlight
    private var activeColor: Color {
        if let hex = hexColor { return Color(hex: hex) }
        return selectedColor.baseColor
    }
    
    var body: some View {
        ScrollView {
            if filteredIcons.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .padding(.top, 30)
            } else {
                LazyVGrid(columns: columns, spacing: Layout.gridSpacing) {
                    ForEach(filteredIcons, id: \.self) { icon in
                        iconButton(icon: icon)
                    }
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, Layout.verticalPadding)
            }
        }
        .safeAreaBar(edge: .bottom) {
            ColorSelectionView(selectedColor: $selectedColor, hexColor: $hexColor)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
        .animation(.snappy, value: searchText)
        .navigationTitle("icon")
        .searchable(text: $searchText)
    }
    
    // MARK: - Private Views
    private func iconButton(icon: String) -> some View {
        let isSelected = selectedIcon == icon
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedIcon = icon
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? activeColor : .secondary.opacity(0.1))
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? .primaryInverse : .primary)
            }
            .frame(width: Layout.circleSize, height: Layout.circleSize)
            .contentShape(Rectangle())
            .scaleEffect(isSelected ? Layout.selectedScale : 1.0)
        }
        .buttonStyle(.plain)
    }
}
