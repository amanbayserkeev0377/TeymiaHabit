import SwiftUI
import CloudKit

struct CloudKitSyncView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var cloudKitStatus: CloudKitStatus = .checking
    @State private var lastSyncTime: Date?
    @State private var isSyncing: Bool = false
    
    private enum CloudKitStatus {
        case checking, available, unavailable, restricted, error(String)
        
        var statusInfo: (String) {
            switch self {
            case .checking:
                return ("icloud_checking_status".localized)
            case .available:
                return ("icloud_sync_active".localized)
            case .unavailable:
                return ("icloud_not_signed_in".localized)
            case .restricted:
                return ("icloud_restricted".localized)
            case .error(let message):
                return (message)
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("icloud_sync_status".localized)
                            .font(.headline)
                        
                        Text(cloudKitStatus.statusInfo)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    if case .checking = cloudKitStatus {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .listRowBackground(Color.mainRowBackground)
            
            if case .available = cloudKitStatus {
                Section {
                    Button {
                        forceiCloudSync()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("icloud_force_sync".localized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .withAppGradient()
                                
                                Text("icloud_force_sync_desc".localized)
                                    .font(.footnote)
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                            }
                            
                            Spacer()
                            
                            if isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isSyncing)
                    
                    if let lastSyncTime = lastSyncTime {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("icloud_last_sync".localized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(formatSyncTime(lastSyncTime))
                                    .font(.footnote)
                                    .foregroundStyle(Color.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text("icloud_manual_sync".localized)
                } footer: {
                    Text("icloud_manual_sync_footer".localized)
                }
                .listRowBackground(Color.mainRowBackground)
            }
            
            Section("icloud_how_sync_works".localized) {
                SyncInfoRow(
                    title: "icloud_automatic_backup".localized,
                    description: "icloud_automatic_backup_desc".localized
                )
                
                SyncInfoRow(
                    title: "icloud_cross_device_sync".localized,
                    description: "icloud_cross_device_sync_desc".localized
                )
                
                SyncInfoRow(
                    title: "icloud_private_secure".localized,
                    description: "icloud_private_secure_desc".localized
                )
            }
            .listRowBackground(Color.mainRowBackground)
            
            if case .unavailable = cloudKitStatus {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("icloud_signin_required".localized)
                                .font(.subheadline)
                            
                            Text("icloud_signin_steps".localized)
                                .font(.footnote)
                                .foregroundStyle(Color.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("icloud_troubleshooting".localized)
                }
                .listRowBackground(Color.mainRowBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.mainGroupBackground)
        .navigationTitle("icloud_sync".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLastSyncTime()
            checkCloudKitStatus()
        }
    }
    
    // MARK: - Private Methods
    
    private func forceiCloudSync() {
        isSyncing = true
        
        Task {
            do {
                try modelContext.save()
                
                // Wait for automatic CloudKit sync
                try await Task.sleep(nanoseconds: 3_000_000_000)
                
                let container = CKContainer(identifier: "iCloud.com.amanbayserkeev.teymiahabit")
                let accountStatus = try await container.accountStatus()
                
                guard accountStatus == .available else {
                    throw CloudKitError.accountNotAvailable
                }
                
                await MainActor.run {
                    let now = Date()
                    lastSyncTime = now
                    UserDefaults.standard.set(now, forKey: "lastSyncTime")
                    isSyncing = false
                    HapticManager.shared.play(.success)
                }
            } catch {
                await MainActor.run {
                    isSyncing = false
                    HapticManager.shared.play(.error)
                }
            }
        }
    }
    
    private func loadLastSyncTime() {
        if let savedTime = UserDefaults.standard.object(forKey: "lastSyncTime") as? Date {
            lastSyncTime = savedTime
        }
    }
    
    private func formatSyncTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "icloud_today_at".localized(with: formatter.string(from: date))
        } else if calendar.isDateInYesterday(date) {
            return "icloud_yesterday_at".localized(with: formatter.string(from: date))
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func checkCloudKitStatus() {
        Task {
            await checkAccountStatus()
        }
    }
    
    @MainActor
    private func checkAccountStatus() async {
        do {
            let container = CKContainer(identifier: "iCloud.com.amanbayserkeev.teymiahabit")
            let accountStatus = try await container.accountStatus()
            
            switch accountStatus {
            case .available:
                do {
                    let database = container.privateCloudDatabase
                    _ = try await database.allRecordZones()
                    cloudKitStatus = .available
                } catch {
                    cloudKitStatus = .error("icloud_database_error".localized)
                }
                
            case .noAccount:
                cloudKitStatus = .unavailable
                
            case .restricted:
                cloudKitStatus = .restricted
                
            case .couldNotDetermine:
                cloudKitStatus = .error("icloud_status_unknown".localized)
                
            case .temporarilyUnavailable:
                cloudKitStatus = .error("icloud_temporarily_unavailable".localized)
                
            @unknown default:
                cloudKitStatus = .error("icloud_unknown_error".localized)
            }
        } catch {
            cloudKitStatus = .error("icloud_check_failed".localized)
        }
    }
}

enum CloudKitError: Error {
    case accountNotAvailable
}

struct SyncInfoRow: View {
    let title: String
    let description: String
    
    var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        .padding(.vertical, 4)
    }
}
