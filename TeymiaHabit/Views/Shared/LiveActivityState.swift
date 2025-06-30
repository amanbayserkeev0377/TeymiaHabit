import SwiftUI

// MARK: - Separate Observable class for Live Activity state
@Observable @MainActor
final class LiveActivityState {
    var hasActiveLiveActivity: Bool = false
    
    func update(_ state: Bool) {
        hasActiveLiveActivity = state
    }
}
