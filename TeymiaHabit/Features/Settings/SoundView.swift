import SwiftUI
import SwiftData

struct SoundView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SoundManager.self) private var soundManager
    @Environment(NotificationManager.self) private var notificationManager
    
    @State private var selectedTab: SoundTab = .completion
    
    enum SoundTab: String, CaseIterable {
        case completion, notification
        
        var localizedName: LocalizedStringResource {
            switch self {
            case .completion: return "sound_tab_completion"
            case .notification: return "sound_tab_notification"
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                Picker("", selection: $selectedTab) {
                    ForEach(SoundTab.allCases, id: \.self) { tab in
                        Text(tab.localizedName).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 500)
                .listRowBackground(Color.clear)
            }
            
            if selectedTab == .completion {
                completionSection
            } else {
                notificationSection
            }
        }
        .formStyle(.grouped)
        .navigationTitle("settings_sounds")
    }
    
    // MARK: - Sections
    
    private var completionSection: some View {
        Group {
            Section {
                Toggle("enable_sounds", isOn: Binding(
                    get: { soundManager.isSoundEnabled },
                    set: { newValue in
                        withAnimation(.snappy) {
                            soundManager.setSoundEnabled(newValue)
                        }
                    }
                ))
            }
            
            if soundManager.isSoundEnabled {
                Section {
                    ForEach(CompletionSound.allCases) { sound in
                        SoundSelectionRowView(
                            sound: sound,
                            isSelected: soundManager.selectedSound == sound
                        ) {
                            handleCompletionSelect(sound)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var notificationSection: some View {
        Section {
            ForEach(NotificationSound.allCases) { sound in
                SoundSelectionRowView(
                    sound: sound,
                    isSelected: notificationManager.selectedNotificationSound == sound
                ) {
                    handleNotificationSelect(sound)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Handlers
    
    private func handleCompletionSelect(_ sound: CompletionSound) {
        soundManager.playSound(sound)
        
            soundManager.setSelectedSound(sound)
    }
    
    private func handleNotificationSelect(_ sound: NotificationSound) {
        soundManager.playNotificationPreview(sound)
        
            Task {
                await notificationManager.setSelectedNotificationSound(sound, modelContext: modelContext)
            }
    }
}

struct SoundSelectionRowView<T: HabitSoundProtocol>: View {
    let sound: T
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            withAnimation(.snappy) {
                action()
            }
        } label: {
            HStack {
                Text(sound.displayName).foregroundStyle(Color.primary)
                
                Spacer()
                
                if isSelected {
                    SelectionCheckmark()
                }
            }
        }
    }
}
