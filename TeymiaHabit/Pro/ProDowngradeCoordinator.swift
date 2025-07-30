import SwiftUI
import SwiftData

@Observable @MainActor
final class ProDowngradeCoordinator {
    static let shared = ProDowngradeCoordinator()
    
    private var modelContext: ModelContext?
    
    private init() {
        setupProStatusObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }
    
    private func setupProStatusObserver() {
        NotificationCenter.default.addObserver(
            forName: .proStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleProStatusChange()
            }
        }
    }
    
    // MARK: - Main Handler
    private func handleProStatusChange() async {
        guard !ProManager.shared.isPro else {
            return
        }
        
        resetUIPreferences()
        
        if let context = modelContext {
            await resetDatabaseFeatures(context: context)
        }
    }
    
    // MARK: - UI Preferences Reset
    private func resetUIPreferences() {
        AppColorManager.shared.resetToDefault()
        AppIconManager.shared.resetToDefault()
        SoundManager.shared.validateSelectedSoundForProStatus()
    }
    
    // MARK: - Database Features Reset
    private func resetDatabaseFeatures(context: ModelContext) async {
        await HabitIconService.shared.resetProIconsToDefault(modelContext: context)
        await NotificationManager.shared.limitRemindersForFreeTier(modelContext: context)
    }
}
