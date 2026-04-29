import SwiftUI

@Observable
final class NavigationManager {
    var selectedTab: AppTab = .habits
    var habitToOpen: Habit? = nil
    
    @MainActor
    func openHabit(_ habit: Habit) {
        selectedTab = .habits
        habitToOpen = habit
    }
}
