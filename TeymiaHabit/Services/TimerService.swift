import Foundation
import SwiftUI

@Observable @MainActor
final class TimerService {
    static let shared = TimerService()
    
    // MARK: - State
    private var activeTimers: [String: TimerData] = [:]
    private var uiTimer: Timer?
    
    // MARK: - UI Update Trigger
    private(set) var updateTrigger: Int = 0
        
    // MARK: - Configuration
    private let maxTimers = 5
    
    // MARK: - Timer Data
    private struct TimerData {
        let habitId: String
        let startTime: Date
        let baseProgress: Int // Progress when timer started
    }
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get current live progress for active timer (returns nil if timer not running)
    func getLiveProgress(for habitId: String) -> Int? {
        guard let timerData = activeTimers[habitId] else { return nil }
        let elapsed = Int(Date().timeIntervalSince(timerData.startTime))
        let currentProgress = timerData.baseProgress + elapsed
        return min(currentProgress, 86400) // Cap at 24 hours
    }
    
    /// Check if timer is running for habit
    func isTimerRunning(for habitId: String) -> Bool {
        return activeTimers[habitId] != nil
    }
    
    /// Start timer for habit with base progress
    func startTimer(for habitId: String, baseProgress: Int) -> Bool {
        // Check if already running
        if activeTimers[habitId] != nil {
            print("⚠️ Timer already running for: \(habitId)")
            return true
        }
        
        // Check timer limit
        guard activeTimers.count < maxTimers else {
            print("❌ Timer limit reached: \(activeTimers.count)/\(maxTimers)")
            return false
        }
        
        // Create new timer
        activeTimers[habitId] = TimerData(
            habitId: habitId,
            startTime: Date(),
            baseProgress: baseProgress
        )
        
        // Start UI updates if this is the first timer
        if activeTimers.count == 1 {
            startUITimer()
        }
        
        triggerUIUpdate()
        print("✅ Timer started: \(habitId), base: \(baseProgress) (\(activeTimers.count)/\(maxTimers))")
        return true
    }
    
    /// Stop timer and return final progress
    func stopTimer(for habitId: String) -> Int? {
        guard let timerData = activeTimers[habitId] else {
            print("⚠️ Timer was not running for: \(habitId)")
            return nil
        }
        
        // Calculate final progress
        let elapsed = Int(Date().timeIntervalSince(timerData.startTime))
        let finalProgress = min(timerData.baseProgress + elapsed, 86400) // Cap at 24 hours
        
        // Remove timer
        activeTimers.removeValue(forKey: habitId)
        
        // Stop UI updates if no more timers
        if activeTimers.isEmpty {
            stopUITimer()
        }
        
        triggerUIUpdate()
        print("✅ Timer stopped: \(habitId), final: \(finalProgress) (remaining: \(activeTimers.count))")
        return finalProgress
    }
    
    /// Get timer start time (for Live Activities)
    func getTimerStartTime(for habitId: String) -> Date? {
        return activeTimers[habitId]?.startTime
    }
    
    // MARK: - Status
    
    var activeTimerCount: Int {
        return activeTimers.count
    }
    
    var canStartNewTimer: Bool {
        return activeTimers.count < maxTimers
    }
    
    var remainingSlots: Int {
        return maxTimers - activeTimers.count
    }
    
    var hasActiveTimers: Bool {
        return !activeTimers.isEmpty
    }
    
    // MARK: - Cleanup
    
    /// Stop all timers (useful for app lifecycle events)
    func stopAllTimers() -> [String: Int] {
        var finalProgresses: [String: Int] = [:]
        
        for habitId in activeTimers.keys {
            if let finalProgress = stopTimer(for: habitId) {
                finalProgresses[habitId] = finalProgress
            }
        }
        
        return finalProgresses
    }
    
    // MARK: - UI Timer Management
    
    private func startUITimer() {
        // Stop existing timer first
        uiTimer?.invalidate()
        
        // Create new timer that triggers UI updates every second
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.triggerUIUpdate()
            }
        }
        
        print("⏱️ UI Timer started for \(activeTimers.count) active timers")
    }
    
    private func stopUITimer() {
        uiTimer?.invalidate()
        uiTimer = nil
        print("⏱️ UI Timer stopped")
    }
    
    // MARK: - UI Update Helper
    
    private func triggerUIUpdate() {
        updateTrigger += 1
    }
    
    // MARK: - App Lifecycle Support
    
    /// Call when app enters background (for Live Activities)
    func handleAppDidEnterBackground() {
        print("🌙 TimerService: App entered background with \(activeTimers.count) active timers")
        
        // Print debug info for Live Activities
        for (habitId, timerData) in activeTimers {
            let elapsed = Int(Date().timeIntervalSince(timerData.startTime))
            let currentProgress = timerData.baseProgress + elapsed
            print("   - \(habitId): \(currentProgress) total (\(elapsed)s elapsed)")
        }
    }
    
    /// Call when app enters foreground
    func handleAppWillEnterForeground() {
        print("☀️ TimerService: App entering foreground")
        
        // Restart UI timer if we have active timers but no UI timer
        if !activeTimers.isEmpty && uiTimer == nil {
            print("☀️ Restarting UI timer for \(activeTimers.count) active timers")
            startUITimer()
        }
        
        // Force UI update to refresh all views
        triggerUIUpdate()
        
        // Debug current state
        if !activeTimers.isEmpty {
            print("☀️ Active timers after foreground:")
            for (habitId, timerData) in activeTimers {
                let elapsed = Int(Date().timeIntervalSince(timerData.startTime))
                let currentProgress = timerData.baseProgress + elapsed
                print("   - \(habitId): \(currentProgress) total (\(elapsed)s elapsed)")
            }
        }
    }
    
    /// Check if any timers are from previous day and clean them up
    func cleanupStaleTimers() {
        let calendar = Calendar.current
        let now = Date()
        var staleTimers: [String] = []
        
        for (habitId, timerData) in activeTimers {
            // If timer is from a different day, mark as stale
            if !calendar.isDate(timerData.startTime, inSameDayAs: now) {
                staleTimers.append(habitId)
            }
        }
        
        // Remove stale timers
        for habitId in staleTimers {
            print("🗑️ Removing stale timer: \(habitId)")
            activeTimers.removeValue(forKey: habitId)
        }
        
        // Stop UI timer if no timers left
        if activeTimers.isEmpty && uiTimer != nil {
            stopUITimer()
        }
        
        if !staleTimers.isEmpty {
            triggerUIUpdate()
        }
    }
    
    // MARK: - Debug Helpers
    
    func debugCurrentState() {
        print("🔍 TimerService Debug State:")
        print("   Active timers: \(activeTimers.count)/\(maxTimers)")
        print("   UI Timer running: \(uiTimer != nil)")
        print("   Update trigger: \(updateTrigger)")
        
        for (habitId, timerData) in activeTimers {
            let elapsed = Int(Date().timeIntervalSince(timerData.startTime))
            let currentProgress = timerData.baseProgress + elapsed
            print("   - \(habitId): base=\(timerData.baseProgress), elapsed=\(elapsed), current=\(currentProgress)")
        }
    }
}
