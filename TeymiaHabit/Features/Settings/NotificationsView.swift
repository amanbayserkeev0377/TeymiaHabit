import SwiftUI
import SwiftData

struct NotificationsRowView: View {
    @Environment(\.modelContext) private var modelContext
    private let manager = NotificationManager.shared
    
    @State private var isPermissionAlertPresented = false

    var body: some View {
        Toggle(isOn: Binding(
            get: { manager.notificationsEnabled },
            set: { newValue in
                Task { await handleToggle(to: newValue) }
            }
        )) {
            Label(
                title: { Text("settings_notifications") },
                icon: {
                    Image(systemName: "bell.badge")
                        .iconStyle()
                        .symbolEffect(.wiggle, value: manager.notificationsEnabled)
                }
            )
        }
        .alert("alert_notifications_permission", isPresented: $isPermissionAlertPresented) {
            Button("button_cancel", role: .cancel) { }
            Button("button_settings") { openSettings() }
        } message: {
            Text("alert_notifications_permission_message")
        }.tint(Color.primary)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await manager.refreshPermissionStatus() }
        }
    }

    @MainActor
    private func handleToggle(to newValue: Bool) async {
        if newValue {
            let isAuthorized = await manager.ensureAuthorization()
            if isAuthorized {
                manager.notificationsEnabled = true
                await manager.updateAllNotifications(modelContext: modelContext)
            } else {
                isPermissionAlertPresented = true
            }
        } else {
            manager.notificationsEnabled = false
            await manager.updateAllNotifications(modelContext: modelContext)
        }
        HapticManager.shared.playSelection()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
