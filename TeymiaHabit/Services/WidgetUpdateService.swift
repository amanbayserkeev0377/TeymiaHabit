import Foundation
import WidgetKit

/// Service for managing Home Screen widget updates
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
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
