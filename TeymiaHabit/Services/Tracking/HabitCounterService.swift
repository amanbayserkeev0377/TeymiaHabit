import SwiftUI
import SwiftData

@Observable
final class HabitCounterService: ProgressTrackingService {
    static let shared = HabitCounterService()
    
    // MARK: - Properties
    
    /// Прогресс для всех счетчиков
    private(set) var progressUpdates: [String: Int] = [:]
    private var lastSaveDate: String = ""
    
    // MARK: - Initialization
    
    private init() {
        loadState()
        checkDayChange()
    }
    
    // MARK: - Day Change Detection
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func checkDayChange() {
        let today = currentDateString
        
        // If this is a new day, clear all progress
        if lastSaveDate != today && lastSaveDate != "" {
            print("🗓️ Day changed from \(lastSaveDate) to \(today) - clearing counter progress")
            progressUpdates.removeAll()
        }
        
        lastSaveDate = today
        saveState()
    }
    
    // MARK: - ProgressTrackingService Implementation
    
    func getCurrentProgress(for habitId: String) -> Int {
        // Check for day change first
        checkDayChange()
        return progressUpdates[habitId] ?? 0
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        // Check for day change first
        checkDayChange()
        
        let currentValue = progressUpdates[habitId] ?? 0
        let newValue = max(0, currentValue + value)
        
        if currentValue != newValue {
            progressUpdates[habitId] = newValue
            saveState()
        }
    }
    
    func resetProgress(for habitId: String) {
        // Check for day change first
        checkDayChange()
        
        if progressUpdates[habitId] != nil && progressUpdates[habitId] != 0 {
            progressUpdates[habitId] = 0
            saveState()
        }
    }
    
    // MARK: - Methods for Timers (stubs - not used for counters)
    
    func isTimerRunning(for habitId: String) -> Bool { return false }
    func startTimer(for habitId: String, initialProgress: Int = 0) { }
    func stopTimer(for habitId: String) { }
    
    // MARK: - Saving and Loading
    
    private func saveState() {
        let state = CounterServiceState(
            progressUpdates: progressUpdates,
            lastSaveDate: lastSaveDate
        )
        
        if let encodedData = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encodedData, forKey: "habit.counter.data")
        }
    }
    
    private func loadState() {
        if let savedData = UserDefaults.standard.data(forKey: "habit.counter.data"),
           let decodedState = try? JSONDecoder().decode(CounterServiceState.self, from: savedData) {
            progressUpdates = decodedState.progressUpdates
            lastSaveDate = decodedState.lastSaveDate
        } else {
            // Migration: try to load old format
            if let savedData = UserDefaults.standard.data(forKey: "habit.counter.data"),
               let decodedData = try? JSONDecoder().decode([String: Int].self, from: savedData) {
                progressUpdates = decodedData
                lastSaveDate = currentDateString
                saveState() // Save in new format
            }
        }
    }
}

// MARK: - Helper Struct for State Persistence
private struct CounterServiceState: Codable {
    let progressUpdates: [String: Int]
    let lastSaveDate: String
}
