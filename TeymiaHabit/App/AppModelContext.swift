import SwiftData
import Foundation

// Singleton для доступа к основному ModelContext приложения
@MainActor
final class AppModelContext {
    static let shared = AppModelContext()
    
    private var _modelContext: ModelContext?
    
    private init() {}
    
    var modelContext: ModelContext? {
        return _modelContext
    }
    
    func setModelContext(_ context: ModelContext) {
        _modelContext = context
        print("✅ AppModelContext set successfully")
    }
}
