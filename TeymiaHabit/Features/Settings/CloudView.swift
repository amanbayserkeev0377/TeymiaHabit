import SwiftUI
import CloudKit

struct CloudRowView: View {
    var body: some View {
        NavigationLink(destination: CloudView()) {
            Label(
                title: { Text("settings_icloud") },
                icon: { Image(systemName: "checkmark.icloud").iconStyle() }
            )
        }
    }
}

struct CloudView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var cloudManager = CloudManager.shared

    var body: some View {
        List {
            Section {
                Image("ui-cloud.lock.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.gray.gradient)
            }
            .listRowBackground(Color.clear)

            Section("icloud_sync_status") {
                StatusRow(status: cloudManager.status)
            }
            .listRowBackground(Color.rowBackground)

            if case .available = cloudManager.status {
                Section("icloud_manual_sync") {
                    Button {
                        Task { await cloudManager.sync(context: modelContext) }
                    } label: {
                        SyncActionRow(isSyncing: cloudManager.isSyncing)
                    }
                    .disabled(cloudManager.isSyncing)

                    if let lastTime = cloudManager.lastSyncTime {
                        LastSyncRow(date: lastTime)
                    }
                }
                .listRowBackground(Color.rowBackground)
            }
            
            Section("icloud_how_sync_works") {
                CloudInfoRow(icon: "arrow.trianglehead.2.clockwise.rotate.90.icloud", title: "icloud_auto", desc: "icloud_auto_desc")
                CloudInfoRow(icon: "macbook.badge.checkmark", title: "icloud_cross_device_sync", desc: "icloud_cross_device_sync_desc")
                CloudInfoRow(icon: "checkmark.shield", title: "icloud_secure", desc: "icloud_secure_desc")
            }
            .listRowBackground(Color.rowBackground)
        }
        .appBackground()
        .navigationTitle("settings_icloud")
        .task { await cloudManager.checkStatus() }
    }
}

// MARK: - Helpers

private struct LastSyncRow: View {
    let date: Date
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("icloud_last_sync")
                    .foregroundStyle(.primary)
                
                Text(formatDate(date))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            let time = date.formatted(date: .omitted, time: .shortened)
            return String(localized: "icloud_today_at \(time)")
        } else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }
}

private struct StatusRow: View {
    let status: CloudManager.CloudStatus
    var body: some View {
        HStack {
            Text(status.info).font(.headline)
            Spacer()
            if status == .checking { ProgressView() }
        }
    }
}

private struct SyncActionRow: View {
    let isSyncing: Bool
    var body: some View {
        HStack {
            Text("icloud_force_sync")
                .fontWeight(.semibold)
                .foregroundStyle(.mainApp.gradient)
            Spacer()
            if isSyncing { ProgressView() }
        }
    }
}

private struct CloudInfoRow: View {
    let icon: String
    let title: LocalizedStringResource
    let desc: LocalizedStringResource
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.primary.gradient)
            VStack(alignment: .leading) {
                Text(title).fontWeight(.medium)
                Text(desc).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
