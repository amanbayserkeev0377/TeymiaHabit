import Foundation
import WidgetKit

@MainActor
final class WidgetUpdateService {
    static let shared = WidgetUpdateService()
    
    private init() {}
    
    /// Главный метод обновления виджетов
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 Widgets reloaded")
    }
    
    /// Обновление с задержкой для синхронизации с базой данных
    func reloadWidgetsAfterDataChange() {
        Task {
            // Ждем чтобы данные сохранились в App Group
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 Widgets reloaded after data change")
        }
    }
}
