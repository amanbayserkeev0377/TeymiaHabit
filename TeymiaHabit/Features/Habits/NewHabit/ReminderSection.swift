import SwiftUI
import UserNotifications

struct ReminderSection: View {
    @Binding var isReminderEnabled: Bool
    @Binding var reminderTimes: [Date]
    @Environment(ProManager.self) private var proManager
    
    @State private var isNotificationPermissionAlertPresented = false
    @State private var isProcessingToggle = false
    
    let onShowPaywall: () -> Void
    
    var body: some View {
        Section {
            Toggle(isOn: Binding(
                get: { isReminderEnabled },
                set: { newValue in
                    guard !isProcessingToggle else { return }
                    
                    if newValue {
                        isProcessingToggle = true
                        Task {
                            await handleReminderToggle(newValue)
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isReminderEnabled = newValue
                        }
                    }
                }
            )) {
                Label(
                    title: { Text("reminders") },
                    icon: {
                        RowIcon(systemName: "bell")
                            .symbolEffect(.wiggle, value: isReminderEnabled)
                    }
                )
            }
            .disabled(isProcessingToggle)
            
            if isReminderEnabled {
                Group {
                    ForEach(Array(reminderTimes.indices), id: \.self) { index in
                        HStack {
                            Text("reminder" + " \(index + 1)")
                            Spacer()
                            DatePicker(
                                "",
                                selection: $reminderTimes[index],
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            
                            if reminderTimes.count > 1 && (proManager.isPro || index > 0) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if reminderTimes.indices.contains(index) {
                                            reminderTimes.remove(at: index)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red.gradient)
                                }
                            }
                        }
                    }
                    
                    if reminderTimes.count < proManager.maxRemindersCount {
                        Button {
                            if reminderTimes.count >= 1 && !proManager.isPro {
                                onShowPaywall()
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    reminderTimes.append(Date())
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("add_reminder")
                            }
                            .fontWeight(.medium)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .alert("alert_notifications_permission", isPresented: $isNotificationPermissionAlertPresented) {
            Button("button_cancel", role: .cancel) { }
            Button("settings") {
                openSettings()
            }
        } message: {
            Text("alert_notifications_permission_message")
        }.tint(Color.primary)
    }
    
    // MARK: - Private Methods
    
    private func handleReminderToggle(_ newValue: Bool) async {
        let isAuthorized = await NotificationManager.shared.ensureAuthorization()
        
        await MainActor.run {
            isProcessingToggle = false
            
            if !isAuthorized {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isReminderEnabled = false
                }
                isNotificationPermissionAlertPresented = true
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isReminderEnabled = newValue
                }
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
