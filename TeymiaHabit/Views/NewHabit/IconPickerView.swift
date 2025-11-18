import SwiftUI

struct CategorySection: Identifiable {
    let id = UUID()
    let name: String
    let icons: [String]
}

struct IconPickerView: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    @Environment(\.dismiss) private var dismiss
    
    
    // MARK: - ICONS
    
    private let categories: [CategorySection] = [
        CategorySection(name: "sport".localized, icons: [
            "yoga", "lunge", "pilates", "swimming", "skiing", "gym",
            "volleyball", "football", "basketball", "tennis", "rugby", "ping.pong",
            "badminton", "golf", "bowling", "bow.arrow", "mask.swim",
            "chess.knight", "equipment", "judo", "medal", "trophy", "laurel.first"
        ]),
        
        CategorySection(name: "productivity".localized, icons: [
            "education", "book.bookmark", "glasses", "square.root", "physics", "ai.assistant",
            "language.exchange", "pen.paintbrush", "code", "code.monitor", "head.brain", "calendar.daily",
            "envelope", "at", "checklist", "checklist.task", "watch.smart", "books",
            "case", "clock.alarm", "chair.office", "inbox", "tools"
        ]),
        
        CategorySection(name: "health".localized, icons: [
            "food.drinks", "coffee", "fast.food", "apple", "bananas", "chopsticks.noodles",
            "bowl.rice", "croissant", "fish", "grocery.basket", "hamburger", "pizza",
            "alcohol", "cocktail", "health", "dental", "hospital", "eye",
            "heart.rate", "lungs", "health.plus", "smoking", "stethoscope",
        ]),
        
        CategorySection(name: "self-care".localized, icons: [
            "cosmetics", "scissors", "bath", "bed.empty", "handwash", "shower.gel",
            "hand.gel", "barbershop", "beard", "comb", "face.smileheart", "face.massage",
            "hair.clipper", "hairbrush", "heart.brain", "hottub", "massage", "self.care",
            "shower.down", "barefoot", "lips", "head.mirror", "mirror"
        ]),
        
        CategorySection(name: "hobbies".localized, icons: [
            "entertainment", "cinema", "events", "hobbies", "gaming", "clapper.open",
            "film", "drum", "guitar", "music", "piano", "play.alt",
            "puzzle", "camera", "camera.video", "drawing", "camping", "fishing",
            "chess",  "chef", "dance.ballet", "hiking", "frying"
        ]),
        
        CategorySection(name: "lifestyle".localized, icons: [
            "shopping", "clothing",  "electronics", "housing", "home.maintenance", "electricity",
            "tv.cable", "bolt", "lamp.desk",  "toilet.paper", "wrench", "family",
            "child", "gifts.parties", "paw", "cat", "toys.accessories", "gift",
            "travel", "vacation", "world", "transport", "bike",
        ]),
        
        CategorySection(name: "finance".localized, icons: [
            "investment", "bank", "credit.card", "wallet", "piggy.bank", "dollar",
            "expense", "dollar.sack", "coins", "chart.pie", "cash", "bitcoin.sign",
            "cash.simple", "coin", "hand.usd", "hands.usd", "usd.circle", "trading",
            "calculator", "receipt", "mortgage", "deposit", "face.money",
        ]),
        
        CategorySection(name: "brands".localized, icons: [
            "instagram", "whatsapp", "threads", "twitter", "meta", "github",
            "shopify", "tik.tok", "telegram", "vk", "youtube", "spotify",
            "reddit", "appstore", "apple.company", "android", "discord", "twitch",
            "bitcoin", "ethereum","mcdonalds", "burger.king",  "netflix",
        ]),
        
        CategorySection(name: "other".localized, icons: [
            "pencil", "clock", "moon", "diamond", "paperclip", "poop",
            "sparkles", "bell", "phone", "comment", "dice", "flame",
            "folder", "headset", "heart", "info", "umbrella", "paperplane",
            "phone.flip", "rocket", "like", "trees", "keyboard"
        ]),
    ]
    
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 6)
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 30) {
                ForEach(categories) { category in
                    categorySection(category)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(.mainBackground)
    }
    
    private func categorySection(_ category: CategorySection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.name)
                .font(.title2)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(category.icons, id: \.self) { icon in
                    iconButton(icon: icon)
                }
            }
        }
    }
    
    private func iconButton(icon: String) -> some View {
        let isSelected = selectedIcon == icon
        
        return Button {
            selectedIcon = icon
            dismiss()
            HapticManager.shared.playSelection()
        } label: {
            ZStack {
                Circle()
                    .fill(.secondary.opacity(0.1))
                
                Image(icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.primary)
            }
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .strokeBorder(isSelected ? .secondary.opacity(0.6) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
