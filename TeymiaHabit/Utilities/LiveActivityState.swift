import SwiftUI

@Observable @MainActor
final class LiveActivityState {
    var hasActiveLiveActivity: Bool = false
    
    func update(_ state: Bool) {
        hasActiveLiveActivity = state
    }
}
