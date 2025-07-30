import SwiftData
import Foundation

@MainActor
final class HabitIconService {
    static let shared = HabitIconService()
    
    private init() {}
    
    /// Reset Pro 3D icons to default SF Symbols when losing Pro access
    func resetProIconsToDefault(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Habit>()
        guard let allHabits = try? modelContext.fetch(descriptor) else { return }
        
        var changedHabitsCount = 0
        
        for habit in allHabits {
            if let iconName = habit.iconName, is3DIcon(iconName) {
                habit.iconName = "checkmark"
                changedHabitsCount += 1
            }
        }
        
        if changedHabitsCount > 0 {
            try? modelContext.save()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if icon is a Pro 3D icon
    private func is3DIcon(_ iconName: String) -> Bool {
        iconName.hasPrefix("3d_") || iconName.hasPrefix("img_3d_")
    }
}
