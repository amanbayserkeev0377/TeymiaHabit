import Foundation
import SwiftUI

@Observable @MainActor
final class TimerService {
    static let shared = TimerService()
    
    private var activeTimers: [String: TimerData] = [:]
    private var uiTimer: Timer?
    private(set) var updateTrigger: Int = 0
    private let maxTimers = 10
    
    private struct TimerData {
        let habitId: String
        let startTime: Date
        let baseProgress: Int
    }
    
    private init() {}
    
    // MARK: - Timer Management
    
    func getLiveProgress(for habitId: String) -> Int? {
        guard let timerData = activeTimers[habitId] else { return nil }
        let elapsed = Int(Date().timeIntervalSince(timerData.startTime))
        let currentProgress = timerData.baseProgress + elapsed
        return min(currentProgress, 86400)
    }
    
    func isTimerRunning(for habitId: String) -> Bool {
        activeTimers[habitId] != nil
    }
    
    func startTimer(for habitId: String, baseProgress: Int) -> Bool {
        if activeTimers[habitId] != nil { return true }
        
        guard activeTimers.count < maxTimers else { return false }
        
        activeTimers[habitId] = TimerData(
            habitId: habitId,
            startTime: Date(),
            baseProgress: baseProgress
        )
        
        if uiTimer == nil {
            startUITimer()
        }
        
        triggerUIUpdate()
        return true
    }
    
    @discardableResult
    func stopTimer(for habitId: String) -> Int? {
        guard let timerData = activeTimers[habitId] else { return nil }
        
        let elapsed = Int(Date().timeIntervalSince(timerData.startTime))
        let finalProgress = min(timerData.baseProgress + elapsed, 86400)
        
        activeTimers.removeValue(forKey: habitId)
        
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
    
    var canStartNewTimer: Bool {
        activeTimers.count < maxTimers
    }
    
    var remainingSlots: Int {
        maxTimers - activeTimers.count
    }
    
    var hasActiveTimers: Bool {
        !activeTimers.isEmpty
    }
    
    /// Stop all timers and return final progresses
    func stopAllTimers() -> [String: Int] {
        var finalProgresses: [String: Int] = [:]
        
        for habitId in activeTimers.keys {
            if let finalProgress = stopTimer(for: habitId) {
                finalProgresses[habitId] = finalProgress
            }
        }
        
        return finalProgresses
    }
    
    // MARK: - App Lifecycle
    
    func handleAppDidEnterBackground() {
        // Background handling for Live Activities - timers continue running
    }
    
    func handleAppWillEnterForeground() {
        if !activeTimers.isEmpty && uiTimer == nil {
            startUITimer()
        }
        
        triggerUIUpdate()
    }
    
    /// Check if any timers are from previous day and clean them up
    func cleanupStaleTimers() {
        let calendar = Calendar.current
        let now = Date()
        var staleTimers: [String] = []
        
        for (habitId, timerData) in activeTimers {
            if !calendar.isDate(timerData.startTime, inSameDayAs: now) {
                staleTimers.append(habitId)
            }
        }
        
        for habitId in staleTimers {
            activeTimers.removeValue(forKey: habitId)
        }
        
        if activeTimers.isEmpty && uiTimer != nil {
            stopUITimer()
        }
        
        if !staleTimers.isEmpty {
            triggerUIUpdate()
        }
    }
    
    // MARK: - Private Methods
    
    private func startUITimer() {
        uiTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTrigger += 1
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.tolerance = 0.1
        uiTimer = timer
    }
    
    private func stopUITimer() {
        uiTimer?.invalidate()
        uiTimer = nil
    }
    
    func triggerUIUpdate() {
        updateTrigger += 1
    }
}
