import Foundation
import WidgetKit

@MainActor
final class WidgetUpdateService {
    static let shared = WidgetUpdateService()
    
    private init() {}
    
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Reload widgets with delay for database synchronization
    func reloadWidgetsAfterDataChange() {
        Task {
            // Wait for data to sync to App Group
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
