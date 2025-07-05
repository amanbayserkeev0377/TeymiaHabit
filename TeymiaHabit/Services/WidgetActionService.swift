import Foundation
import SwiftUI

// MARK: - Clean Widget Action Service
@Observable @MainActor
final class WidgetActionService {
    static let shared = WidgetActionService()
    
    // Use AsyncStream for reactive, type-safe handling
    private var continuation: AsyncStream<WidgetActionNotification>.Continuation?
    private let actionStream: AsyncStream<WidgetActionNotification>
    
    private init() {
        // ИСПРАВЛЕНИЕ: правильный порядок инициализации
        var tempContinuation: AsyncStream<WidgetActionNotification>.Continuation?
        
        // Create AsyncStream с захватом continuation
        actionStream = AsyncStream { continuation in
            tempContinuation = continuation
        }
        
        // Сохраняем continuation после инициализации stream
        self.continuation = tempContinuation
        
        setupNotificationListener()
    }
    
    private func setupNotificationListener() {
        // ИСПРАВЛЕНИЕ: захватываем continuation вне closure для Swift 6
        NotificationCenter.default.addObserver(
            forName: .widgetActionReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let action = notification.object as? WidgetActionNotification else { return }
            print("📡 WidgetActionService received: \(action.action) for \(action.habitId)")
            
            // Используем Task для MainActor доступа
            Task { @MainActor in
                self.continuation?.yield(action)
            }
        }
    }
    
    // Public API for observing actions
    func observeActions(for habitId: String) -> AsyncStream<WidgetAction> {
        AsyncStream { continuation in
            Task {
                for await action in actionStream {
                    if action.habitId == habitId {
                        continuation.yield(action.action)
                    }
                }
                continuation.finish()
            }
        }
    }
    
    // ИСПРАВЛЕНИЕ: метод для явной очистки
    func cleanup() {
        continuation?.finish()
        NotificationCenter.default.removeObserver(self)
    }
    
    // ИСПРАВЛЕНИЕ: убираем deinit - для singleton не критично
    // В случае необходимости можно вызвать cleanup() вручную
}
