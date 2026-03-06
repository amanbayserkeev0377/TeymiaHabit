import SwiftUI
import CloudKit
import SwiftData

@Observable @MainActor
final class CloudManager {
    static let shared = CloudManager()
    
    var status: CloudStatus = .checking
    var lastSyncTime: Date? = UserDefaults.standard.object(forKey: "lastSyncTime") as? Date
    var isSyncing = false

    enum CloudStatus {
        case checking, available, unavailable, restricted, error(String)
        
        var info: LocalizedStringResource {
            switch self {
            case .checking:    "icloud_checking_status"
            case .available:   "icloud_sync_active"
            case .unavailable: "icloud_not_signed_in"
            case .restricted:  "icloud_restricted"
            case .error(let m): LocalizedStringResource(stringLiteral: m)
            }
        }
    }

    func checkStatus() async {
        let container = CKContainer(identifier: "iCloud.com.amanbayserkeev.teymiahabit")
        do {
            let accountStatus = try await container.accountStatus()
            switch accountStatus {
            case .available: status = .available
            case .noAccount: status = .unavailable
            default:         status = .error("icloud_status_unknown")
            }
        } catch {
            status = .error("icloud_check_failed")
        }
    }

    func sync(context: ModelContext) async {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            try context.save()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            let now = Date()
            lastSyncTime = now
            UserDefaults.standard.set(now, forKey: "lastSyncTime")
            HapticManager.shared.play(.success)
        } catch {
            HapticManager.shared.play(.error)
        }
    }
}

extension CloudManager.CloudStatus: Equatable {
    static func == (lhs: CloudManager.CloudStatus, rhs: CloudManager.CloudStatus) -> Bool {
        switch (lhs, rhs) {
        case (.checking, .checking): return true
        case (.available, .available): return true
        case (.unavailable, .unavailable): return true
        case (.restricted, .restricted): return true
        case (.error(let l), .error(let r)): return l == r
        default: return false
        }
    }
}
