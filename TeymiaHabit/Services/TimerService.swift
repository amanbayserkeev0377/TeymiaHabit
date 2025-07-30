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
    
    func isTimerRunning(for habitId: String) -> Bool {
        activeTimers[habitId] != nil
    }
    
    func startTimer(for habitId: String, baseProgress: Int) -> Bool {
        // Check if already running
        if activeTimers[habitId] != nil {
            return true
        }
        
        // Check timer limit
        guard activeTimers.count < maxTimers else {
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
        return true
    }
    
    /// Stop timer and return final progress
    func stopTimer(for habitId: String) -> Int? {
        guard let timerData = activeTimers[habitId] else {
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
        return finalProgress
    }
    
    func getTimerStartTime(for habitId: String) -> Date? {
        activeTimers[habitId]?.startTime
    }
    
    // MARK: - Status
    
    var activeTimerCount: Int {
        activeTimers.count
    }
    
    var canStartNewTimer: Bool {
        activeTimers.count < maxTimers
    }
    
    var remainingSlots: Int {
        maxTimers - activeTimers.count
    }
    
    var hasActiveTimers: Bool {
        !activeTimers.isEmpty
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
    }
    
    private func stopUITimer() {
        uiTimer?.invalidate()
        uiTimer = nil
    }
    
    // MARK: - UI Update Helper
    
    private func triggerUIUpdate() {
        updateTrigger += 1
    }
    
    // MARK: - App Lifecycle Support
    
    func handleAppDidEnterBackground() {
        // Background handling for Live Activities
        // Timers continue running, UI timer stops automatically
    }
    
    func handleAppWillEnterForeground() {
        // Restart UI timer if we have active timers but no UI timer
        if !activeTimers.isEmpty && uiTimer == nil {
            startUITimer()
        }
        
        // Force UI update to refresh all views
        triggerUIUpdate()
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
}
