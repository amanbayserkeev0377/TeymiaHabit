import SwiftUI

struct SoundSettingsView: View {
    @Environment(ProManager.self) private var proManager
    @State private var soundManager = SoundManager.shared
    @State private var showProPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                // Sound Toggle Section
                Section {
                    Toggle("Enable Completion Sounds", isOn: Binding(
                        get: { soundManager.isSoundEnabled },
                        set: { soundManager.setSoundEnabled($0) } // ✅ Используем новый метод
                    ))
                } header: {
                    Text("Sound Settings")
                } footer: {
                    Text("Play a sound when you complete a habit")
                }
                
                // Sound Selection Section - ✅ Показываем только если звуки включены
                if soundManager.isSoundEnabled {
                    Section {
                        ForEach(CompletionSound.allCases) { sound in
                            SoundRowView(
                                sound: sound,
                                isSelected: soundManager.selectedSound == sound,
                                isPro: proManager.isPro
                            ) {
                                selectSound(sound)
                            }
                        }
                    } header: {
                        Text("Completion Sounds")
                    }
                }
            }
            .navigationTitle("Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showProPaywall) {
                PaywallView()
            }
        }
    }
    
    private func selectSound(_ sound: CompletionSound) {
        // Check if sound requires Pro FIRST
        if sound.requiresPro && !proManager.isPro {
            // Play preview first
            soundManager.playSound(sound)
            
            // Show paywall after a short delay to let preview play
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showProPaywall = true
            }
            return
        }
        
        // ✅ Play preview for selected sound
        soundManager.playSound(sound)
        
        // ✅ Set as selected sound using new method
        soundManager.setSelectedSound(sound)
        
        // Provide haptic feedback
        HapticManager.shared.playSelection()
    }
}

// MARK: - Sound Row View
struct SoundRowView: View {
    let sound: CompletionSound
    let isSelected: Bool
    let isPro: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Sound name
                VStack(alignment: .leading, spacing: 2) {
                    Text(sound.displayName)
                        .font(.body)
                        .foregroundStyle(Color(UIColor.label))
                }
                
                Spacer()
                
                // ✅ Галочка для выбранного звука
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .withAppGradient()
                    .opacity(isSelected ? 1 : 0)
                    .animation(.easeInOut, value: isSelected)
                
                // ✅ ProLockBadge для платных звуков
                if sound.requiresPro && !isPro {
                    ProLockBadge()
                }
            }
            .contentShape(Rectangle())
        }
    }
}
