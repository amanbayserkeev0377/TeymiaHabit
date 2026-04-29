import SwiftUI

struct CategorySection: Identifiable, Hashable {
    let id: String
    let name: String
    let icons: [String]
    
    init(name: String, icons: [String]) {
        self.id = name
        self.name = name
        self.icons = icons
    }
}

struct IconPickerView: View {
    // MARK: - Bindings
    @Binding var selectedIcon: String
    @Binding var selectedColor: HabitIconColor
    @Binding var hexColor: String?
    @State private var searchText: String = ""
    
    // MARK: - Layout Constants
    private enum Layout {
        static let circleSize: CGFloat = 44
        static let gridSpacing: CGFloat = 14
        static let selectedScale: CGFloat = 1.15
        static let horizontalPadding: CGFloat = DS.Spacing.s16
        static let verticalPadding: CGFloat = DS.Spacing.s16
    }
    
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Layout.gridSpacing), count: 6
    )
    
    private var filteredSections: [CategorySection] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        if query.isEmpty { return categories }
        
        return categories.compactMap { section in
            let matchingIcons = section.icons.filter { $0.lowercased().contains(query) }
            return matchingIcons.isEmpty ? nil : CategorySection(name: section.name, icons: matchingIcons)
        }
    }
    
    private var activeColor: Color {
        if let hex = hexColor { return Color(hex: hex) }
        return selectedColor.baseColor
    }
    
    var body: some View {
        ScrollView {
            if filteredSections.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .padding(.top, 30)
            } else {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(filteredSections) { section in
                        Section(header: sectionHeader(section.name)) {
                            LazyVGrid(columns: columns, spacing: Layout.gridSpacing) {
                                ForEach(section.icons, id: \.self) { icon in
                                    iconButton(icon: icon)
                                }
                            }
                            .padding(.horizontal, Layout.horizontalPadding)
                        }
                    }
                }
                .padding(.vertical, Layout.verticalPadding)
            }
        }
        .sensoryFeedback(.selection, trigger: selectedIcon)
        .safeAreaBar(edge: .bottom) {
            ColorSelectionView(selectedColor: $selectedColor, hexColor: $hexColor)
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.bottom, 6)
        }
        .animation(.snappy, value: searchText)
        .navigationTitle("icon")
//        .navigationBarTitleDisplayMode(.inline) TODO
        .searchable(text: $searchText)
    }
    
    // MARK: - Private Views
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DS.Typography.titleMedium)
            .foregroundStyle(.primary)
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, DS.Spacing.s8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
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
                
                Image(icon)
                    .resizable()
                    .frame(size: DS.Icon.s24)
                    .foregroundStyle(isSelected ? Color.blackWhite : .primary)
            }
            .frame(width: Layout.circleSize, height: Layout.circleSize)
            .contentShape(Rectangle())
            .scaleEffect(isSelected ? Layout.selectedScale : 1.0)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Icons
    private let categories: [CategorySection] = [
        CategorySection(name: "sport", icons: [
            "person.yoga", "person.yoga.fill", "person.meditation", "person.meditation.fill", "person.yoga.ball", "person.yoga.ball.fill",
            "person.windsurf", "person.windsurf.fill", "person.volleyball", "person.volleyball.fill", "person.treadmill", "person.treadmill.fill",
            "person.tennis", "person.tennis.fill", "person.swimmer", "person.swimmer.fill", "person.running", "person.running.fill",
            "person.pilates", "person.pilates.fill", "person.lunge", "person.lunge.fill", "person.football", "person.football.fill",
            "person.gym", "person.gym.fill", "person.biking", "person.biking.fill", "tennis", "tennis.fill",
            "volleyball", "volleyball.fill", "basketball", "basketball.fill", "basketball2", "basketball2.fill",
            "football", "football.fill", "football.court", "football.court.fill", "rugby", "rugby.fill",
            "rugby.helmet", "rugby.helmet.fill", "american.football", "american.football.fill", "golf", "golf.fill",
            "golf2", "golf2.fill", "badminton", "badminton.fill", "ping.pong", "ping.pong.fill",
            "bowling", "bowling.fill", "boxing", "boxing.fill", "judo", "judo.fill",
            "canoe", "canoe.fill", "fishing", "fishing.fill", "diving.glasses", "diving.glasses.fill",
            "mask.snorkel", "mask.snorkel.fill", "ski.boots", "ski.boots.fill", "motorcycle.helmet", "motorcycle.helmet.fill",
            "gym", "gym.fill", "gym.arm", "gym.arm.fill", "gym.bag", "gym.bag.fill",
            "gym.bolt", "gym.bolt.fill", "gym.apple", "gym.apple.fill", "sport.water", "sport.water.fill",
            "massage", "massage.fill", "chess", "chess.fill", "chess.knight", "chess.knight.fill",
            "finish.flag", "finish.flag.fill", "first.laurel", "first.laurel.fill", "medal.first", "medal.first.fill",
            "medal.star", "medal.star.fill", "trophy", "trophy.fill", "badget.check", "badget.check.fill"
        ]),
        
        CategorySection(name: "productivity", icons: [
            "book", "book.fill", "book2", "book2.fill", "book.bookmark", "book.bookmark.fill",
            "books", "books.fill", "book.person", "book.person.fill", "book.brain", "book.brain.fill",
            "book.quran", "book.quran.fill", "bookmark", "bookmark.fill", "brain", "brain.fill",
            "brain.lightning", "brain.lightning.fill", "head.brain", "head.brain.fill", "ai", "ai.fill",
            "education", "education.fill", "education.person", "education.person.fill", "education.trophy", "education.trophy.fill",
            "math", "math.fill", "math2", "math2.fill", "physics", "physics.fill",
            "science", "science.fill", "puzzle", "puzzle.fill", "language", "language.fill",
            "calculator", "calculator.fill", "keyboard", "keyboard.fill", "keyboard.typing", "keyboard.typing.fill",
            "code", "code.fill", "code.laptop", "code.laptop.fill", "code.monitor", "code.monitor.fill",
            "code.window", "code.window.fill", "react", "react.fill", "rocket", "rocket.fill",
            "briefcase", "briefcase.fill", "office.desk", "office.desk.fill", "office.chair", "office.chair.fill",
            "lampdesk", "lampdesk.fill", "bulb", "bulb.fill", "handshake", "handshake.fill",
            "hand.pencil", "hand.pencil.fill", "pencil.paintbrush", "pencil.paintbrush.fill", "notebook", "notebook.fill",
            "document.scroll", "document.scroll.fill", "task.checklist", "task.checklist.fill", "inbox", "inbox.fill",
            "inbox2", "inbox2.fill", "thumbstack", "thumbstack.fill", "paperplane", "paperplane.fill",
            "envelope", "envelope.fill", "phone", "phone.fill", "watch.smart", "watch.smart.fill",
            "calendar.daily", "calendar.daily.fill", "clock", "clock.fill", "clock.alarm", "clock.alarm.fill",
            "clock.check", "clock.check.fill", "clock.hourglass", "clock.hourglass.fill", "chart.poll", "chart.poll.fill",
            "target", "target.fill", "target2", "target2.fill", "bolt", "bolt.fill"
        ]),
        
        CategorySection(name: "health", icons: [
            "doctor", "doctor.fill", "doctor.case", "doctor.case.fill", "nurse", "nurse.fill",
            "hospital", "hospital.fill", "medical", "medical.fill", "gynecology", "gynecology.fill",
            "heart.brain", "heart.brain.fill", "head.heart", "head.heart.fill", "head.brain.bolt", "head.brain.bolt.fill",
            "hands.brain", "hands.brain.fill", "person.stress", "person.stress.fill", "virus.slash", "virus.slash.fill",
            "lungs", "lungs.fill", "tooth", "tooth.fill", "nose", "nose.fill",
            "ear", "ear.fill", "eye", "eye.fill", "eyes", "eyes.fill",
            "eye.health", "eye.health.fill", "lips", "lips.fill", "body", "body.fill",
            "brain", "brain.fill", "apple", "apple.fill", "avocado", "avocado.fill",
            "broccoli", "broccoli.fill", "carrot", "carrot.fill", "egg", "egg.fill",
            "fish", "fish.fill", "bottle", "bottle.fill", "pills", "pills.fill",
            "pills.capsule", "pills.capsule.fill", "smoking", "smoking.fill", "beer", "beer.fill",
            "champagne", "champagne.fill", "cocktail", "cocktail.fill", "coffee", "coffee.fill",
            "cup.hot", "cup.hot.fill", "candy", "candy.fill", "hamburger", "hamburger.fill",
            "hamburger.soda", "hamburger.soda.fill", "pizza", "pizza.fill"
        ]),
        
        CategorySection(name: "self-care", icons: [
            "face.smile.tongue", "face.smile.tongue.fill", "face.sunglasses", "face.sunglasses.fill", "face.awesome", "face.awesome.fill",
            "face.drooling", "face.drooling.fill", "face.sleeping", "face.sleeping.fill", "person.heart", "person.heart.fill",
            "hands.heart", "hands.heart.fill", "hands.heart2", "hands.heart2.fill", "hand.sparkles", "hand.sparkles.fill",
            "hand.seeding", "hand.seeding.fill", "hands.gel", "hands.gel.fill", "hand.scissors", "hand.scissors.fill",
            "mirror", "mirror.fill", "mirror.face", "mirror.face.fill", "makeup.bag", "makeup.bag.fill",
            "lipstick", "lipstick.fill", "mascara", "mascara.fill", "eyeshadow", "eyeshadow.fill",
            "blush", "blush.fill", "nail.art", "nail.art.fill", "manicure", "manicure.fill",
            "comb", "comb.fill", "hair.clipper", "hair.clipper.fill", "hairdryer", "hairdryer.fill",
            "hair.conditioner", "hair.conditioner.fill", "straightener", "straightener.fill", "beard", "beard.fill",
            "bath", "bath.fill", "bath2", "bath2.fill", "shower", "shower.fill",
            "shower.down", "shower.down.fill", "shower.gel", "shower.gel.fill", "cream", "cream.fill",
            "toothbrush", "toothbrush.fill", "bed", "bed.fill", "bed.person", "bed.person.fill",
            "barefoot", "barefoot.fill", "footprint", "footprint.fill", "air.freshener", "air.freshener.fill",
            "scissors", "scissors.fill", "facial.massage", "facial.massage.fill", "moustache", "moustache.fill"
        ]),
        
        CategorySection(name: "hobbies", icons: [
            "ballet.dance", "ballet.dance.fill", "theater.masks", "theater.masks.fill", "clapper.open", "clapper.open.fill",
            "video.camera.alt", "video.camera.alt.fill", "camera", "camera.fill", "picture", "picture.fill",
            "palette", "palette.fill", "brush", "brush.fill", "pen.swirl", "pen.swirl.fill",
            "photo.film.music", "photo.film.music.fill", "circle.microphone", "circle.microphone.fill", "microphone", "microphone.fill",
            "microphone.alt", "microphone.alt.fill", "play.microphone", "play.microphone.fill", "k.pop.microphone", "k.pop.microphone.fill",
            "headset", "headset.fill", "piano.keyboard", "piano.keyboard.fill", "guitar", "guitar.fill",
            "guitar.electric", "guitar.electric.fill", "drum", "drum.fill", "user.dj", "user.dj.fill",
            "gamepad", "gamepad.fill", "dice", "dice.fill", "dice.d6", "dice.d6.fill",
            "puzzle.alt", "puzzle.alt.fill", "club", "club.fill", "kite", "kite.fill",
            "hiking", "hiking.fill", "camping", "camping.fill", "campfire", "campfire.fill",
            "grill.fire", "grill.fire.fill", "pan.frying", "pan.frying.fill", "steak", "steak.fill",
            "user.chef", "user.chef.fill", "glass.cheers", "glass.cheers.fill", "popcorn", "popcorn.fill",
            "play.alt", "play.alt.fill", "play.circle", "play.circle.fill", "swing", "swing.fill"
        ]),
        
        CategorySection(name: "lifestyle", icons: [
            "face.smile", "face.smile.fill", "face.smile.beam", "face.smile.beam.fill", "face.smile.hearts", "face.smile.hearts.fill",
            "face.smiling.hands", "face.smiling.hands.fill", "face.party", "face.party.fill", "face.pleading", "face.pleading.fill",
            "face.relieved", "face.relieved.fill", "face.sad.sweat", "face.sad.sweat.fill", "face.meh", "face.meh.fill",
            "face.unamused", "face.unamused.fill", "baby", "baby.fill", "smiling.baby", "smiling.baby.fill",
            "baby.carriage", "baby.carriage.fill", "teddy.bear", "teddy.bear.fill", "family", "family.fill",
            "pets", "pets.fill", "paw", "paw.fill", "cat", "cat.fill",
            "cat.dog", "cat.dog.fill", "dog.leashed", "dog.leashed.fill", "sleeping.cat", "sleeping.cat.fill",
            "home", "home.fill", "house.chimney", "house.chimney.fill", "tools", "tools.fill",
            "wrench", "wrench.fill", "toilet", "toilet.fill", "toiletpaper", "toiletpaper.fill",
            "clothes.hanger", "clothes.hanger.fill", "shirt", "shirt.fill", "tshirt", "tshirt.fill",
            "dress", "dress.fill", "shopping.bag", "shopping.bag.fill", "shopping.basket", "shopping.basket.fill",
            "shopping.cart", "shopping.cart.fill", "grocery.basket", "grocery.basket.fill", "marketplace", "marketplace.fill",
            "receipt", "receipt.fill", "gift.box", "gift.box.fill", "balloons", "balloons.fill",
            "cake.birthday", "cake.birthday.fill", "party.horn", "party.horn.fill", "glass.cheers", "glass.cheers.fill",
            "plane", "plane.fill", "earth.americas", "earth.americas.fill", "compass", "compass.fill",
            "umbrella.beach", "umbrella.beach.fill", "hat.beach", "hat.beach.fill", "surfing", "surfing.fill",
            "person.luggage", "person.luggage.fill", "car.side", "car.side.fill", "motorcycle", "motorcycle.fill",
            "circle.phone", "circle.phone.fill", "laptop", "laptop.fill", "tv.retro", "tv.retro.fill",
            "life", "life.fill"
            
        ])
        ,
        
        CategorySection(name: "brands", icons: [
            "apple.logo", "android", "google", "meta", "facebook", "instagram",
            "threads", "twitter.x", "linkedin", "reddit", "pinterest", "vk",
            "telegram", "whatsapp", "discord", "slack", "twitch", "youtube",
            "spotify", "netflix", "hbo", "nvidia", "shopify", "github",
            "appstore", "swift", "python", "html5", "photoshop", "illustrator",
            "firefox", "yandex", "tik.tok", "mcdonalds", "burger.king", "starbucks",
            "bitcoin", "ethereum"
        ]),
        
        CategorySection(name: "other", icons: [
            "heart", "heart.fill", "anatomical.heart", "anatomical.heart.fill", "sparkles", "sparkles.fill",
            "diamond", "diamond.fill", "fire.flame", "fire.flame.fill", "flame", "flame.fill",
            "moon.stars", "moon.stars.fill", "sun", "sun.fill", "torch", "torch.fill",
            "candle.holder", "candle.holder.fill", "bell.ring", "bell.ring.fill", "comment.dots", "comment.dots.fill",
            "folder", "folder.fill", "folder.open", "folder.open.fill", "paperclip", "paperclip.fill",
            "info", "info.fill", "phone.flip", "phone.flip.fill", "music.alt", "music.alt.fill",
            "k.pop", "k.pop.fill", "alien", "alien.fill", "skull", "skull.fill",
            "poop", "poop.fill", "tombstone", "tombstone.fill"
        ])
    ]
}
