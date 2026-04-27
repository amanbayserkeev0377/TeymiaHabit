import SwiftUI

// MARK: - No-op implementations for defaultValue

@MainActor
private final class NoOpHabitService: HabitServiceProtocol {
    nonisolated init() {}
    func completeHabit(for habit: Habit, date: Date) -> Bool { false }
    func addProgress(_ delta: Int, to habit: Habit, date: Date) -> Bool { false }
    func updateProgress(to newValue: Int, for habit: Habit, date: Date) -> Bool { false }
    func saveProgress(_ value: Int, for habit: Habit, date: Date) {}
    func resetProgress(for habit: Habit, date: Date) {}
    func skipDate(_ date: Date, for habit: Habit) {}
    func unskipDate(_ date: Date, for habit: Habit) {}
    func archive(_ habit: Habit) {}
    func unarchive(_ habit: Habit) {}
    func delete(_ habit: Habit) {}
}

@MainActor
private final class NoOpWidgetService: WidgetServiceProtocol {
    nonisolated init() {}
    func reloadWidgets() {}
    func reloadWidgetsAfterDataChange() {}
}

// MARK: - Environment Keys

struct HabitServiceKey: EnvironmentKey {
    static let defaultValue: any HabitServiceProtocol = NoOpHabitService()
}

struct WidgetServiceKey: EnvironmentKey {
    static let defaultValue: any WidgetServiceProtocol = NoOpWidgetService()
}

// MARK: - Environment Extensions

extension EnvironmentValues {
    var habitService: any HabitServiceProtocol {
        get { self[HabitServiceKey.self] }
        set { self[HabitServiceKey.self] = newValue }
    }
    
    var widgetService: any WidgetServiceProtocol {
        get { self[WidgetServiceKey.self] }
        set { self[WidgetServiceKey.self] = newValue }
    }
}
