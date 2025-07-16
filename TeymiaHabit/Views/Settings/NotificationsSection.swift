import SwiftUI
import SwiftData

struct NotificationsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isNotificationPermissionAlertPresented = false
    
    var body: some View {
        let notificationManager = NotificationManager.shared
        
        Toggle(isOn: Binding(
            get: { notificationManager.notificationsEnabled },
            set: { newValue in
                Task {
                    await handleNotificationToggle(newValue)
                }
            }
        ).animation(.easeInOut(duration: 0.3))) {
            Label(
                title: { Text("notifications".localized) },
                icon: {
                    Image(systemName: "bell.badge.fill")
                        .withIOSSettingsIcon(lightColors: [
                            Color(#colorLiteral(red: 1, green: 0.3, blue: 0.3, alpha: 1)),
                            Color(#colorLiteral(red: 0.8, green: 0.1, blue: 0.1, alpha: 1))
                        ])
                        .symbolEffect(.bounce, options: .repeat(1), value: notificationManager.notificationsEnabled)
                }
            )
        }
        .withToggleColor()
        .alert("alert_notifications_permission".localized, isPresented: $isNotificationPermissionAlertPresented) {
            Button("button_cancel".localized, role: .cancel) { }
            Button("settings".localized) {
                openSettings()
            }
        } message: {
            Text("alert_notifications_permission_message".localized)
        }
    }
    
    private func handleNotificationToggle(_ isEnabled: Bool) async {
        let notificationManager = NotificationManager.shared
        
        guard notificationManager.notificationsEnabled != isEnabled else { return }
        
        if isEnabled {
            notificationManager.notificationsEnabled = true
            
            let isAuthorized = await notificationManager.ensureAuthorization()
            
            await MainActor.run {
                if !isAuthorized {
                    notificationManager.notificationsEnabled = false
                    isNotificationPermissionAlertPresented = true
                }
            }
            
            if isAuthorized {
                await notificationManager.updateAllNotifications(modelContext: modelContext)
            }
        } else {
            notificationManager.notificationsEnabled = false
            await notificationManager.updateAllNotifications(modelContext: modelContext)
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
