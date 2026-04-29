import AVFoundation
import Foundation

// MARK: - SoundManager

@Observable
final class SoundManager {
    private var audioPlayer: AVAudioPlayer?
    private let userDefaults = UserDefaults.standard
    
    private(set) var selectedSound: CompletionSound {
        didSet {
            userDefaults.set(selectedSound.rawValue, forKey: UserDefaults.SoundKeys.selectedCompletionSound)
        }
    }
    
    private(set) var isSoundEnabled: Bool {
        didSet {
            userDefaults.set(isSoundEnabled, forKey: UserDefaults.SoundKeys.completionSoundEnabled)
        }
    }
    
    init() {
        let rawValue = userDefaults.string(forKey: UserDefaults.SoundKeys.selectedCompletionSound) ?? CompletionSound.default.rawValue
        self.selectedSound = CompletionSound(rawValue: rawValue) ?? .default
        
        if userDefaults.object(forKey: UserDefaults.SoundKeys.completionSoundEnabled) == nil {
            self.isSoundEnabled = true
        } else {
            self.isSoundEnabled = userDefaults.bool(forKey: UserDefaults.SoundKeys.completionSoundEnabled)
        }
        
        #if os(iOS)
        setupAudioSession()
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func setSelectedSound(_ sound: CompletionSound) {
        selectedSound = sound
    }
    
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
    }
    
    // MARK: - Audio Playback
    
    func playCompletionSound() {
        guard isSoundEnabled else { return }
        playSound(selectedSound)
    }
    
    func playSound(_ sound: CompletionSound) {
        guard let url = Bundle.main.url(
            forResource: sound.rawValue,
            withExtension: sound.fileExtension
        ) else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.7
            audioPlayer?.play()
        } catch {
            // Silent fail for audio playback errors
        }
    }
    
    func playNotificationPreview(_ sound: NotificationSound) {
        guard sound != .system else { return }
        
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: sound.fileExtension) else { return }
        
        try? audioPlayer = AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }
    
    func stopCurrentSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Silent fail
        }
        #endif
    }
}

// MARK: - UserDefaults Keys

extension UserDefaults {
    enum SoundKeys {
        static let selectedCompletionSound = "selectedCompletionSound"
        static let completionSoundEnabled = "completionSoundEnabled"
    }
}
