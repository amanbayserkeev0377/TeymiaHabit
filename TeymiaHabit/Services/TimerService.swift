import Foundation
import SwiftUI

@Observable @MainActor
final class TimerService {
    static let shared = TimerService()
    
    // MARK: - State
    private(set) var liveProgress: [String: Int] = [:]
    
    // MARK: - UI Update Trigger
    private(set) var updateTrigger: Int = 0
    
    // MARK: - Internal State
    @ObservationIgnored private var activeTimers: [String: TimerData] = [:]
    @ObservationIgnored private var uiTimer: Timer?
    @ObservationIgnored private var lastSaveDate: String = ""
    
    // MARK: - Configuration
    private let maxTimers = 5
    
    // MARK: - Timer Data
    private struct TimerData {
        let habitId: String
        let startTime: Date
        let baseProgress: Int
    }
    
    private init() {
        migrateFromOldTimer()
        restoreState()
        checkDayChange()
    }
    
    // MARK: - Public API
    
    func getCurrentProgress(for habitId: String) -> Int {
        checkDayChange()
        
        if let timerData = activeTimers[habitId] {
            let elapsed = Int(Date().timeIntervalSince(timerData.startTime))
            return timerData.baseProgress + elapsed
        }
        
        return liveProgress[habitId] ?? 0
    }
    
    func isTimerRunning(for habitId: String) -> Bool {
        checkDayChange()
        return activeTimers[habitId] != nil
    }
    
    func startTimer(for habitId: String, initialProgress: Int) -> Bool {
        checkDayChange()
        
        // Check limit
        if activeTimers[habitId] == nil && activeTimers.count >= maxTimers {
            return false
        }
        
        // Already running
        if activeTimers[habitId] != nil {
            return true
        }
        
        // Start new timer
        activeTimers[habitId] = TimerData(
            habitId: habitId,
            startTime: Date(),
            baseProgress: initialProgress
        )
        
        // Start UI timer if first
        if activeTimers.count == 1 {
            startUITimer()
        }
        
        saveState()
        triggerUIUpdate() // ✅ Force UI update immediately
        print("✅ Timer started: \(habitId) (\(activeTimers.count)/\(maxTimers))")
        return true
    }
    
    func stopTimer(for habitId: String) {
        checkDayChange()
        
        guard let timerData = activeTimers[habitId] else { return }
        
        // Calculate final progress
        let elapsed = Int(Date().timeIntervalSince(timerData.startTime))
        let finalProgress = timerData.baseProgress + elapsed
        
        // Save progress
        liveProgress[habitId] = finalProgress
        
        // Remove timer
        activeTimers.removeValue(forKey: habitId)
        
        // CRITICAL: Stop UI timer immediately if no active timers
        if activeTimers.isEmpty {
            stopUITimer()
            print("🛑 UI Timer stopped - no active timers")
        }
        
        saveState()
        triggerUIUpdate() // ✅ Final UI update after stopping
        print("✅ Timer stopped: \(habitId), final: \(finalProgress)")
    }
    
    func setProgress(_ progress: Int, for habitId: String) {
        if activeTimers[habitId] != nil {
            stopTimer(for: habitId)
        }
        liveProgress[habitId] = progress
        triggerUIUpdate() // ✅ Force UI update
        saveState()
    }
    
    func resetProgress(for habitId: String) {
        if activeTimers[habitId] != nil {
            stopTimer(for: habitId)
        }
        liveProgress[habitId] = 0
        triggerUIUpdate() // ✅ Force UI update
        saveState()
    }
    
    // MARK: - Status
    
    var activeTimerCount: Int {
        checkDayChange()
        return activeTimers.count
    }
    
    var canStartNewTimer: Bool {
        checkDayChange()
        return activeTimers.count < maxTimers
    }
    
    var remainingSlots: Int {
        checkDayChange()
        return maxTimers - activeTimers.count
    }
    
    func getTimerStartTime(for habitId: String) -> Date? {
        return activeTimers[habitId]?.startTime
    }
    
    // MARK: - UI Timer
    
    private func startUITimer() {
        // Stop existing timer first
        uiTimer?.invalidate()
        uiTimer = nil
        
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateLiveProgress()
            }
        }
    }
    
    private func stopUITimer() {
        uiTimer?.invalidate()
        uiTimer = nil
    }
    
    private func updateLiveProgress() {
        // CRITICAL: Stop updating if no active timers
        guard !activeTimers.isEmpty else {
            return
        }
        
        var hasChanges = false
        
        for (habitId, timerData) in activeTimers {
            let elapsed = Int(Date().timeIntervalSince(timerData.startTime))
            let newProgress = timerData.baseProgress + elapsed
            
            if liveProgress[habitId] != newProgress {
                liveProgress[habitId] = newProgress
                hasChanges = true
            }
        }
        
        // ONLY trigger UI update if there are actual changes
        if hasChanges {
            triggerUIUpdate()
        }
        
        // Debug print every 5 seconds
        if hasChanges && (liveProgress.values.first ?? 0) % 5 == 0 {
            print("⏱️ UI Update: \(liveProgress)")
        }
    }
    
    // MARK: - UI Update Helper
    
    private func triggerUIUpdate() {
        updateTrigger += 1
    }
    
    // MARK: - Day Change
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func checkDayChange() {
        let today = currentDateString
        
        if lastSaveDate != today && lastSaveDate != "" {
            print("🗓️ Day changed from \(lastSaveDate) to \(today)")
            
            // Stop all timers
            let habitIds = Array(activeTimers.keys)
            for habitId in habitIds {
                stopTimer(for: habitId)
            }
            
            // Clear state
            liveProgress.removeAll()
            clearState()
        }
        
        lastSaveDate = today
    }
    
    // MARK: - Persistence
    
    private func saveState() {
        let state = TimerState(
            activeTimers: activeTimers.mapValues { timer in
                SavedTimer(
                    habitId: timer.habitId,
                    startTime: timer.startTime,
                    baseProgress: timer.baseProgress
                )
            },
            liveProgress: liveProgress,
            lastSaveDate: lastSaveDate
        )
        
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: "TimerService_v1")
        }
    }
    
    private func restoreState() {
        guard let data = UserDefaults.standard.data(forKey: "TimerService_v1"),
              let state = try? JSONDecoder().decode(TimerState.self, from: data) else {
            return
        }
        
        // Check same day
        let today = currentDateString
        guard state.lastSaveDate == today else {
            clearState()
            return
        }
        
        // Restore timers
        for (habitId, savedTimer) in state.activeTimers {
            activeTimers[habitId] = TimerData(
                habitId: savedTimer.habitId,
                startTime: savedTimer.startTime,
                baseProgress: savedTimer.baseProgress
            )
        }
        
        // Restore progress
        liveProgress = state.liveProgress
        lastSaveDate = state.lastSaveDate
        
        // Start UI timer if needed
        if !activeTimers.isEmpty {
            startUITimer()
        }
        
        print("🔄 Restored \(activeTimers.count) timers")
    }
    
    // MARK: - Migration from old ViewModel timer
    
    private func migrateFromOldTimer() {
        // Check for old timer format from your current ViewModel
        let userDefaults = UserDefaults.standard
        let keys = userDefaults.dictionaryRepresentation().keys
        
        for key in keys {
            if key.hasPrefix("timer_") {
                // Extract habit ID from key
                let habitId = String(key.dropFirst(6)) // Remove "timer_" prefix
                
                if let startTime = userDefaults.object(forKey: key) as? Date {
                    // Check if it's from today
                    if Calendar.current.isDate(startTime, inSameDayAs: Date()) {
                        print("🔄 Migrating timer for habit: \(habitId)")
                        
                        // Calculate elapsed time as progress
                        let elapsed = Int(Date().timeIntervalSince(startTime))
                        liveProgress[habitId] = elapsed
                        
                        // Remove old key
                        userDefaults.removeObject(forKey: key)
                    } else {
                        // Remove stale timer
                        userDefaults.removeObject(forKey: key)
                    }
                }
            }
        }
        
        if !liveProgress.isEmpty {
            saveState()
        }
    }
    
    private func clearState() {
        UserDefaults.standard.removeObject(forKey: "TimerService_v1")
        activeTimers.removeAll()
        liveProgress.removeAll()
    }
    
    deinit {
        // Can't call @MainActor methods in deinit
        uiTimer?.invalidate()
        uiTimer = nil
    }
}

// MARK: - State Structures

private struct TimerState: Codable {
    let activeTimers: [String: SavedTimer]
    let liveProgress: [String: Int]
    let lastSaveDate: String
}

private struct SavedTimer: Codable {
    let habitId: String
    let startTime: Date
    let baseProgress: Int
}
