import SwiftData
import Foundation

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
    }
}
