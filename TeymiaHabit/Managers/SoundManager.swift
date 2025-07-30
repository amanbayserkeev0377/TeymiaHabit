import AVFoundation
import Foundation

// MARK: - Sound Types

enum CompletionSound: String, CaseIterable, Identifiable {
    case `default`
    case chime
    case chord
    case click
    case droplet
    case echo
    case flow
    case glow
    case horizon
    case marimba
    case slide
    case sparkle
    case success
    case sunrise
    case surge
    case touch
    case veil
    case violin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "default_sound".localized
        case .chime: return "Chime"
        case .chord: return "Chord"
        case .click: return "Click"
        case .droplet: return "Droplet"
        case .echo: return "Echo"
        case .flow: return "Flow"
        case .glow: return "Glow"
        case .horizon: return "Horizon"
        case .marimba: return "Marimba"
        case .slide: return "Slide"
        case .sparkle: return "Sparkle"
        case .success: return "Success"
        case .sunrise: return "Sunrise"
        case .surge: return "Surge"
        case .touch: return "Touch"
        case .veil: return "Veil"
        case .violin: return "Violin"
        }
    }

    var requiresPro: Bool {
        self != .default
    }
    
    var fileExtension: String {
        "wav"
    }
}

// MARK: - SoundManager

@Observable
final class SoundManager {
    static let shared = SoundManager()
    
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
    
    private init() {
        let rawValue = userDefaults.string(forKey: UserDefaults.SoundKeys.selectedCompletionSound) ?? CompletionSound.default.rawValue
        self.selectedSound = CompletionSound(rawValue: rawValue) ?? .default
        
        if userDefaults.object(forKey: UserDefaults.SoundKeys.completionSoundEnabled) == nil {
            self.isSoundEnabled = true
        } else {
            self.isSoundEnabled = userDefaults.bool(forKey: UserDefaults.SoundKeys.completionSoundEnabled)
        }
        
        setupAudioSession()
        startObservingProStatus()
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
    
    @MainActor
    func validateSelectedSoundForProStatus() {
        if selectedSound.requiresPro && !ProManager.shared.isPro {
            selectedSound = .default
        }
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
    
    func stopCurrentSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - Private Methods
    
    private func startObservingProStatus() {
        NotificationCenter.default.addObserver(
            forName: .proStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.validateSelectedSoundForProStatus()
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Silent fail for audio session setup
        }
    }
}

// MARK: - UserDefaults Keys

extension UserDefaults {
    enum SoundKeys {
        static let selectedCompletionSound = "selectedCompletionSound"
        static let completionSoundEnabled = "completionSoundEnabled"
    }
}
