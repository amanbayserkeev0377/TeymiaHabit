import SwiftUI

struct SoundSettingsView: View {
    @Environment(ProManager.self) private var proManager
    @State private var soundManager = SoundManager.shared
    @State private var showProPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                
                Section {
                    HStack {
                        Spacer()
                        
                        Image("3d_speaker_red")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                        
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
                
                Section {
                    Toggle("completion_sounds".localized, isOn: Binding(
                        get: { soundManager.isSoundEnabled },
                        set: { soundManager.setSoundEnabled($0) }
                    ))
                    .withToggleColor()
                }
                
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
                    }
                }
            }
            .navigationTitle("sounds".localized)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showProPaywall) {
                PaywallView()
            }
        }
    }
    
    private func selectSound(_ sound: CompletionSound) {
        if sound.requiresPro && !proManager.isPro {
            soundManager.playSound(sound)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showProPaywall = true
            }
            return
        }
        soundManager.playSound(sound)
        soundManager.setSelectedSound(sound)
        HapticManager.shared.playSelection()
    }
}

struct SoundRowView: View {
    let sound: CompletionSound
    let isSelected: Bool
    let isPro: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(sound.displayName)
                    .font(.body)
                    .foregroundStyle(Color(UIColor.label))
                
                Spacer()
                
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .withAppGradient()
                    .opacity(isSelected ? 1 : 0)
                    .animation(.easeInOut, value: isSelected)
                
                if sound.requiresPro && !isPro {
                    ProLockBadge()
                }
            }
            .contentShape(Rectangle())
        }
    }
}
