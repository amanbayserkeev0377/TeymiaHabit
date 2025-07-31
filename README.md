# Teymia Habit - iOS Habit Tracker

A modern, feature-rich habit tracking app built with the latest iOS technologies. Published on the App Store and now open-sourced to help developers learn modern iOS development patterns.

## 📱 Screenshots

<div align="center">
  <img src="Screenshots/screenshot1.png" alt="HomeView" width="200"/>
  <img src="Screenshots/screenshot2.png" alt="HomeView" width="200"/>
  <img src="Screenshots/screenshot3.png" alt="HabitDetailView" width="200"/>
  <img src="Screenshots/screenshot4.png" alt="NewHabitView" width="200"/>
</div>

<div align="center">
  <img src="Screenshots/screenshot5.png" alt="IconPickerView" width="200"/>
  <img src="Screenshots/screenshot6.png" alt="HabitStatisticsView" width="200"/>
  <img src="Screenshots/screenshot7.png" alt="HabitStatisticsViewDark" width="200"/>
  <img src="Screenshots/screenshot8.png" alt="Widgets" width="200"/>
</div>

## 🚀 Download

<p align="center">
  <a href="https://apps.apple.com/app/teymia-habit/id6746747903">
    <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83" alt="Download on App Store" height="60">
  </a>
</p>

**⭐ Or build from source using the instructions below!**

## ✨ Features

### Core Features
- **Multiple habit types**: Counter-based and timer-based tracking
- **Concurrent timers**: Run multiple habit timers simultaneously
- **Background persistence**: Timers continue when app is closed
- **Smart scheduling**: Configure active days per habit
- **Progress visualization**: Beautiful charts and calendar views
- **Streak tracking**: Monitor consistency over time
- **Completion sounds**: Audio feedback for achievements
- **Archive system**: Organize completed habits

### Security & Privacy
- **Biometric lock**: Face ID/Touch ID app protection
- **Custom passcode**: 4-digit PIN security
- **Auto-lock**: Configurable timeout settings
- **Privacy-first**: Data stays on your devices only

### iOS 18+ Integration
- **Live Activities**: Interactive timer widgets on Lock Screen
- **Dynamic Island**: Real-time progress updates
- **Home Screen Widgets**: Quick habit overview
- **CloudKit Sync**: Seamless sync across all your devices

### Pro Features
- **Unlimited habits** (Free: 3 habits)
- **Advanced statistics** with detailed charts
- **Multiple reminders** per habit
- **Premium 3D icons** for habits
- **Custom app themes** and colors
- **Lifetime purchase** option

## 🛠 Tech Stack

This app demonstrates modern iOS development with:

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Core Data successor for data persistence
- **CloudKit** - Apple's cloud database solution
- **ActivityKit** - Live Activities and Dynamic Island
- **WidgetKit** - Home Screen and Lock Screen widgets
- **RevenueCat** - In-app purchase management
- **Push Notifications** - Smart reminder system
- **Haptic Feedback** - Enhanced user experience

## 📱 Requirements

- **iOS 18.0+**
- **Xcode 16.0+**
- **Swift 5.10+**

## 🔧 Installation

### Quick Setup

```bash
# Clone the repository
git clone https://github.com/amanbayserkeev0377/Teymia-Habit.git
cd Teymia-Habit

# Open in Xcode
open TeymiaHabit.xcodeproj

# Build and run (⌘+R)
```

### Configuration

The app works out of the box, but you can customize:

#### 1. Bundle Identifier
Change the Bundle ID in Xcode project settings to your own.

#### 2. RevenueCat Setup (Optional)
For in-app purchases, update `RevenueCatConfig.swift`:
```swift
static let apiKey = "YOUR_REVENUECAT_API_KEY"
```

#### 3. CloudKit (Optional)
CloudKit works with any Apple ID, but for production:
1. Update CloudKit container identifier
2. Configure your own iCloud container

## 🏗 Architecture

### Design Patterns
- **MVVM** - Clean separation of concerns
- **Observable** - Modern SwiftUI state management
- **Dependency Injection** - Through SwiftUI Environment
- **Protocol-Oriented Design** - Flexible and testable code

### Project Structure

```
TeymiaHabit/
├── App/                    # App configuration
├── Models/                 # SwiftData models
├── Views/                  # SwiftUI views
├── ViewModels/             # MVVM view models
├── Managers/               # Core managers
├── Services/               # Business logic
├── UI Components/          # Reusable components
├── Extensions/             # Swift extensions
├── Pro/                    # Premium features
├── Sounds/                 # Audio assets
├── LiveActivity/           # Live Activities
└── TeymiaHabitWidgets/     # Widgets
```

### Modern iOS Features Implementation

- **SwiftData Migration** - Proper schema evolution
- **CloudKit Integration** - Private database with conflict resolution
- **Live Activities** - Real-time timer updates
- **App Intents** - Deep linking and Shortcuts support
- **Widget Extensions** - Shared data with App Groups

## 💰 Monetization

This project includes a complete in-app purchase system:

- **Freemium model** with 3 free habits
- **Subscription tiers** (monthly/yearly)
- **Lifetime purchase** option
- **Feature gating** throughout the app
- **RevenueCat integration** for purchase management

Perfect for learning how to implement and manage in-app purchases in a real app.

## 🌍 Localization

Currently supports:
- 🇺🇸 English
- 🇷🇺 Russian  
- 🇰🇬 Kyrgyz
- 🇰🇿 Kazakh
- 🇨🇳 Chinese (Simplified, Traditional, Hong Kong)
- 🇪🇸 Spanish
- 🇫🇷 French
- 🇩🇪 German
- 🇧🇷 Portuguese (Brazil)
- 🇯🇵 Japanese
- 🇰🇷 Korean
- 🇮🇳 Hindi
- 🇹🇷 Turkish
- 🇻🇳 Vietnamese
- 🇮🇹 Italian
- 🇮🇩 Indonesian

All strings are externalized and ready for additional languages.

## 🎯 What You'll Learn

This codebase demonstrates:

### SwiftUI Mastery
- Complex navigation patterns
- Custom animations and transitions
- Advanced layout techniques
- State management best practices

### Data & Persistence
- SwiftData schema design
- CloudKit private database integration
- Data migration strategies
- Efficient Core Data relationships

### iOS Extensions
- Widget development with WidgetKit
- Live Activities implementation
- App Intents for deep linking
- Shared data between main app and extensions

### Production App Development
- In-app purchases with RevenueCat
- Push notifications setup
- Haptic feedback integration
- Accessibility implementation
- Performance optimization

## 🚀 Getting Started

1. **Download from App Store** to see the final product
2. **Clone and build** to explore the implementation
3. **Read the code** - heavily commented for learning
4. **Experiment** - modify features and see the results

## 📖 Learning Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Guide](https://developer.apple.com/documentation/swiftdata)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [ActivityKit Guide](https://developer.apple.com/documentation/activitykit)

## 🤝 Contributing

This is primarily an educational resource, but contributions are welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact

- **App Store**: [Teymia Habit](https://apps.apple.com/app/teymia-habit/id6746747903)
- **GitHub Issues**: For technical questions about the code
- **App Store Reviews**: For feedback about the published app

---

**⭐ If this project helped you learn iOS development, please give it a star!**
