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
        case .default: return "Default"
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
        return self != .default
    }
    
    // File extension
    var fileExtension: String {
        return "wav"
    }
}

// MARK: - SoundManager
@Observable
final class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    private let userDefaults = UserDefaults.standard
    
    // ✅ Используем private(set) для selectedSound чтобы SwiftUI мог отслеживать изменения
    private(set) var selectedSound: CompletionSound {
        didSet {
            userDefaults.set(selectedSound.rawValue, forKey: "selectedCompletionSound")
        }
    }
    
    // ✅ Используем private(set) для isSoundEnabled
    private(set) var isSoundEnabled: Bool {
        didSet {
            userDefaults.set(isSoundEnabled, forKey: "completionSoundEnabled")
        }
    }
    
    private init() {
        // Initialize from UserDefaults
        let rawValue = userDefaults.string(forKey: "selectedCompletionSound") ?? CompletionSound.default.rawValue
        self.selectedSound = CompletionSound(rawValue: rawValue) ?? .default
        
        // Default to enabled if not set
        if userDefaults.object(forKey: "completionSoundEnabled") == nil {
            self.isSoundEnabled = true
        } else {
            self.isSoundEnabled = userDefaults.bool(forKey: "completionSoundEnabled")
        }
        
        setupAudioSession()
        startObservingProStatus()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Update selected sound - this will trigger UI updates
    func setSelectedSound(_ sound: CompletionSound) {
        selectedSound = sound
    }
    
    /// Toggle sound enabled/disabled
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
    }
    
    /// Check and reset to default sound if Pro required and user lost Pro access
    @MainActor
    func validateSelectedSoundForProStatus() {
        if selectedSound.requiresPro && !ProManager.shared.isPro {
            print("🔄 User lost Pro access, resetting sound to default")
            selectedSound = .default // Reset to default free sound
        }
    }
    
    // MARK: - Pro Status Observation
    
    private func startObservingProStatus() {
        // Observe Pro status changes
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
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Play Completion Sound
    func playCompletionSound() {
        guard isSoundEnabled else { return }
        playSound(selectedSound)
    }
    
    // MARK: - Play Specific Sound (for preview)
    func playSound(_ sound: CompletionSound) {
        guard let url = Bundle.main.url(
            forResource: sound.rawValue,
            withExtension: sound.fileExtension
        ) else {
            print("❌ Sound file not found: \(sound.rawValue).\(sound.fileExtension)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.7 // Adjust volume as needed
            audioPlayer?.play()
        } catch {
            print("❌ Failed to play sound: \(error)")
        }
    }
    
    // MARK: - Stop Current Sound
    func stopCurrentSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

// MARK: - UserDefaults Keys Extension
extension UserDefaults {
    enum SoundKeys {
        static let selectedCompletionSound = "selectedCompletionSound"
        static let completionSoundEnabled = "completionSoundEnabled"
    }
}
