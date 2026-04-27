@testable import TeymiaHabit
import Foundation

@MainActor
final class MockWidgetService: WidgetServiceProtocol {
    var reloadCallCount = 0
    var reloadAfterDataChangeCallCount = 0
    
    func reloadWidgets() {
        reloadCallCount += 1
    }
    
    func reloadWidgetsAfterDataChange() {
        reloadAfterDataChangeCallCount += 1
    }
}
