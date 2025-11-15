import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    
    @Environment(\.dismiss) private var dismiss
    @Environment(ProManager.self) private var proManager
    
    let onShowPaywall: () -> Void
    
// MARK: - ICONS
    
    private let allIcons: [String] = [
        "food.drinks", "delivery", "groceries", "restaurant",
        "coffee", "fast.food", "lunches", "apple", "bananas", "chopsticks.noodles", "bowl.rice", "carrot", "croissant", "fish", "grocery.basket", "hamburger", "pizza", "alcohol", "champagne", "cocktail",
        
        "transport", "taxi", "public.transport", "car.bus", "bike", "motorcycle", "subway", "train", "fuel",
        "parking", "repair", "washing",
        
        "entertainment", "cinema", "events", "subscriptions",
        "hobbies", "gaming", "chess.piece", "clapper.open", "film", "game.board", "guitar", "music", "piano", "play.alt", "cards", "puzzle",
        
        "sports", "basketball", "football", "tennis", "rugby", "golf", "ping.pong", "chess.knight", "gym", "swimming", "yoga", "skiing", "equipment", "sport.uniform", "archery", "laurel.first", "medal", "trophy",
        
        "shopping", "cart.shopping", "clothing", "cosmetics", "electronics",
        "gifts", "marketplaces", "shopping.basket", "shopping.bag", "tags",
        
        "health", "dental", "hospital", "pharmacy",
        "checkups", "therapy", "veterinary", "eye", "heart.brain", "heart.rate", "lungs", "medicine", "health.plus", "smoking", "stethoscope", "syringe", "doctor",
        
        "housing", "rent", "furniture", "home.maintenance",
        "internet", "telephone", "water", "electricity",
        "gas", "tv.cable", "bath", "bed.empty", "bolt", "lamp.desk", "paint.roller", "toilet.paper", "wrench",
        
        "family", "family2", "child", "baby", "baby.carriage", "kids.clothes", "school.supplies", "toys.entertainment", "gifts.parties", "pet", "pet.food", "pets", "paw", "cat", "toys.accessories", "birthday.gift", "gift",
        
        "travel", "flights", "visadocument", "hotel", "tours", "vacation", "chinese", "compass", "map.marker", "luggage", "plane.globe", "world",

        "education", "books", "courses", "book.bookmark", "books2", "student", "writer", "scientist", "glasses", "calculator", "square.root", "square.poll", "physics", "react", "ai.technology", "ai.assistant", "language.exchange", "language", "pen.swirl", "pen.paintbrush",
        
        "salary", "monthly.salary", "overtime", "bonus", "business", "freelance", "consulting", "business.revenue", "investment", "dividends", "refund", "cashback", "income", "bank", "credit.card", "wallet", "piggy.bank", "dollar", "expense", "dollar.sack", "dollar.transfer", "coins", "commission", "hand.bill", "hand.revenue", "hand.usd", "chart.pie", "cash", "cash.simple", "bitcoin.lock", "bitcoin.symbol", "crypto.coins", "nft", "briefcase", "transfer",
        
        "visa", "stripe", "paypal", "apple.pay", "amazon.pay", "master.card", "bitcoin", "ethereum", "shopify", "instagram", "whatsapp", "threads", "twitter", "meta", "tik.tok", "telegram", "vk", "youtube", "spotify", "reddit", "github", "appstore", "apple.company", "android", "discord", "starbucks", "nvidia", "soundcloud", "twitch", "huawei", "burger.king", "t.mobile", "airbnb", "mcdonalds", "ebay", "fedex", "flaticon", "netflix", "sony", "uber",
        
        "other", "general", "pencil", "trash", "materials", "sun", "moon", "alien", "candle", "diamond", "paperclip", "poop", "shoe.prints", "snooze", "sparkles", "bell", "bookmark", "clock", "comment", "cursor", "dice", "envelope", "flame", "folder", "footprint", "headset", "heart", "info", "keyboard", "lock", "paperplane", "phone.flip", "rocket", "scissors", "search", "smile", "like", "trees", "umbrella", "wheat", "calendar"
        
    ]
    
    private let freeIcons: Set<String> = [
        "books", "trophy", "archery", "bookmark", "clock", "comment", "cursor",
        "paperplane", "umbrella", "trees", "like", "smile", "scissors"
    ]

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 6)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(allIcons, id: \.self) { iconName in
                    iconButton(for: iconName)
                }
            }
            .padding()
        }
        .background(.mainBackground)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private func iconButton(for iconName: String) -> some View {
        let isFree = freeIcons.contains(iconName)
        let isPro = proManager.isPro
        let isLocked = !isFree && !isPro
        let isSelected = selectedIcon == iconName && !isLocked
        
        return Button {
            if isLocked {
                onShowPaywall()
            } else {
                selectedIcon = iconName
                dismiss()
                HapticManager.shared.playSelection()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.secondary.opacity(0.1))
                
                Image(iconName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.primary)
                    .opacity(isLocked ? 0.4 : 1.0)
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Circle().fill(.black.opacity(0.7)))
                        .offset(x: 10, y: 10)
                }
            }
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .strokeBorder(isSelected ? selectedColor.color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
