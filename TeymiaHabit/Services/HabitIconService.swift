import SwiftData
import Foundation

@MainActor
final class HabitIconService {
    static let shared = HabitIconService()
    
    private init() {}
    
    // MARK: - Helper Methods
    
    /// Check if icon is a Pro 3D icon
    private func is3DIcon(_ iconName: String) -> Bool {
        iconName.hasPrefix("3d_") || iconName.hasPrefix("img_3d_")
    }
}
