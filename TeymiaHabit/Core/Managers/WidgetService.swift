import WidgetKit

// MARK: - Protocol
@MainActor
protocol WidgetServiceProtocol {
    func reloadWidgets()
    func reloadWidgetsAfterDataChange()
}

// MARK: - Implementation
@Observable @MainActor
final class WidgetService: WidgetServiceProtocol {
    private let appGroup = "group.com.amanbayserkeev.teymiahabit"
    
    init() {}
    
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func reloadWidgetsAfterDataChange() {
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
