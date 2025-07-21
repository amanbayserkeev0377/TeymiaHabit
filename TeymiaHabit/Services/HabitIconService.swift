import SwiftData
import Foundation

// MARK: - Service for handling habit icon downgrades
@MainActor
final class HabitIconService {
    static let shared = HabitIconService()
    
    private init() {}
    
    /// Reset Pro 3D icons to default SF Symbols when losing Pro access
    func resetProIconsToDefault(modelContext: ModelContext) async {
        print("📋 Resetting Pro 3D icons to default SF Symbols")
        
        do {
            let descriptor = FetchDescriptor<Habit>()
            let allHabits = try modelContext.fetch(descriptor)
            
            var changedHabitsCount = 0
            
            for habit in allHabits {
                if let iconName = habit.iconName, is3DIcon(iconName) {
                    // Reset to default SF Symbol
                    habit.iconName = "checkmark"
                    changedHabitsCount += 1
                    
                    print("📋 Reset icon for '\(habit.title)' from '\(iconName)' to 'checkmark'")
                }
            }
            
            if changedHabitsCount > 0 {
                try modelContext.save()
                print("✅ Reset icons for \(changedHabitsCount) habits")
            }
            
        } catch {
            print("❌ Failed to reset habit icons: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if icon is a Pro 3D icon
    private func is3DIcon(_ iconName: String) -> Bool {
        // ✅ Проверяем оба формата: "3d_..." и "img_3d_..."
        return iconName.hasPrefix("3d_") || iconName.hasPrefix("img_3d_")
    }
}
