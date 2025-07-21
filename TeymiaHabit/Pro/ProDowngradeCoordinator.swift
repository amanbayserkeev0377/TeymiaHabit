import SwiftUI
import SwiftData

// MARK: - Coordinator for handling Pro status downgrades
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
    
    /// Inject ModelContext for database operations
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
            print("✅ User still has Pro access, no downgrade needed")
            return
        }
        
        print("🔄 Pro status lost - initiating graceful downgrade...")
        
        // Reset UI preferences (immediate, no database needed)
        resetUIPreferences()
        
        // Reset database-dependent features (if context available)
        if let context = modelContext {
            await resetDatabaseFeatures(context: context)
        } else {
            print("⚠️ ModelContext not available for database operations")
        }
        
        print("✅ Pro downgrade completed successfully")
    }
    
    // MARK: - UI Preferences Reset
    
    private func resetUIPreferences() {
        print("🎨 Resetting UI preferences to defaults...")
        
        // Reset app color
        AppColorManager.shared.resetToDefault()
        
        // Reset app icon
        AppIconManager.shared.resetToDefault()
        
        // Reset completion sound (handled by SoundManager observer)
        SoundManager.shared.validateSelectedSoundForProStatus()
        
        print("✅ UI preferences reset completed")
    }
    
    // MARK: - Database Features Reset
    
    private func resetDatabaseFeatures(context: ModelContext) async {
        print("🗃️ Resetting database-dependent Pro features...")
        
        // Reset 3D habit icons to SF Symbols
        await HabitIconService.shared.resetProIconsToDefault(modelContext: context)
        
        // Limit reminders to 2 per habit
        await NotificationManager.shared.limitRemindersForFreeTier(modelContext: context)
        
        print("✅ Database features reset completed")
    }
}
