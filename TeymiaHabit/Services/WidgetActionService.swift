import Foundation
import SwiftUI

// MARK: - Clean Widget Action Service
@Observable @MainActor
final class WidgetActionService {
    static let shared = WidgetActionService()
    
    // ИСПРАВЛЕНИЕ: Используем Subject для множественных подписчиков
    private var actionSubject = ActionSubject()
    
    private init() {
        setupNotificationListener()
    }
    
    private func setupNotificationListener() {
        NotificationCenter.default.addObserver(
            forName: .widgetActionReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let action = notification.object as? WidgetActionNotification else { return }
            print("📡 WidgetActionService received: \(action.action) for \(action.habitId)")
            
            // ИСПРАВЛЕНИЕ: Используем Task для MainActor доступа
            Task { @MainActor [weak self] in
                self?.actionSubject.send(action)
            }
        }
    }
    
    // Public API for observing actions
    func observeActions(for habitId: String) -> AsyncStream<WidgetAction> {
        print("🔗 Creating AsyncStream for habitId: \(habitId)")
        
        return AsyncStream { continuation in
            let cancellable = actionSubject.sink { action in
                print("🔄 ActionSubject received action: \(action.action) for habitId: \(action.habitId)")
                if action.habitId == habitId {
                    print("✅ Forwarding action \(action.action) to habitId: \(habitId)")
                    continuation.yield(action.action)
                } else {
                    print("❌ Ignoring action for different habitId: \(action.habitId) (expected: \(habitId))")
                }
            }
            
            continuation.onTermination = { _ in
                cancellable.cancel()
                print("🔗 AsyncStream terminated for habitId: \(habitId)")
            }
        }
    }
    
    func cleanup() {
        actionSubject.finish()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Simple Subject Implementation
private final class ActionSubject {
    private var continuations: [UUID: (WidgetActionNotification) -> Void] = [:]
    
    func send(_ action: WidgetActionNotification) {
        print("📤 ActionSubject sending to \(continuations.count) subscribers")
        for handler in continuations.values {
            handler(action)
        }
    }
    
    func sink(_ handler: @escaping (WidgetActionNotification) -> Void) -> Cancellable {
        let id = UUID()
        continuations[id] = handler
        print("📝 ActionSubject: Added subscriber \(id), total: \(continuations.count)")
        
        return Cancellable { [weak self] in
            self?.continuations.removeValue(forKey: id)
            print("🗑️ ActionSubject: Removed subscriber \(id)")
        }
    }
    
    func finish() {
        continuations.removeAll()
        print("🏁 ActionSubject finished")
    }
}

private final class Cancellable {
    private let onCancel: () -> Void
    
    init(_ onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }
    
    func cancel() {
        onCancel()
    }
}
