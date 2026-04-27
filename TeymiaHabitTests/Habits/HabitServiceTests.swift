import Testing
import Foundation
@testable import TeymiaHabit

@MainActor
@Suite("HabitService Tests")
struct HabitServiceTests {
    
    // MARK: - Setup
    let dataSource: MockHabitDataSource
    let widgetService: MockWidgetService
    let sut: HabitService
    
    init() {
        dataSource = MockHabitDataSource()
        widgetService = MockWidgetService()
        sut = HabitService(
            dataSource: dataSource,
            widgetService: widgetService
        )
    }
    
    // MARK: - Helper
    func makeHabit(goal: Int = 5, type: HabitType = .count) -> Habit {
        Habit(
            title: "Test Habit",
            type: type,
            goal: goal,
            iconName: "star"
        )
    }
    
    // MARK: - completeHabit
    
    @Test("Complete habit — returns true when not completed")
    func completeHabit_returnsTrue_whenNotCompleted() {
        let habit = makeHabit(goal: 1)
        let result = sut.completeHabit(for: habit, date: .now)
        #expect(result == true)
    }
    
    @Test("Complete habit — returns false when already completed")
    func completeHabit_returnsFalse_whenAlreadyCompleted() {
        let habit = makeHabit(goal: 1)
        sut.completeHabit(for: habit, date: .now)
        let result = sut.completeHabit(for: habit, date: .now)
        #expect(result == false)
    }
    
    @Test("Complete habit — inserts completion into dataSource")
    func completeHabit_insertsCompletion() {
        let habit = makeHabit(goal: 1)
        sut.completeHabit(for: habit, date: .now)
        #expect(dataSource.insertCompletionCallCount == 1)
    }
    
    // MARK: - addProgress
    
    @Test("Add progress — returns true when goal reached")
    func addProgress_returnsTrue_whenGoalReached() {
        let habit = makeHabit(goal: 1)
        let result = sut.addProgress(1, to: habit, date: .now)
        #expect(result == true)
    }
    
    @Test("Add progress — returns false when goal not reached")
    func addProgress_returnsFalse_whenGoalNotReached() {
        let habit = makeHabit(goal: 5)
        let result = sut.addProgress(1, to: habit, date: .now)
        #expect(result == false)
    }
    
    @Test("Add progress — does not go below zero")
    func addProgress_doesNotGoBelowZero() {
        let habit = makeHabit(goal: 5)
        sut.addProgress(-100, to: habit, date: .now)
        #expect(dataSource.insertCompletionCallCount == 0)
    }
    
    // MARK: - skip
    
    @Test("Skip date — adds to skippedDates")
    func skipDate_addsToSkippedDates() {
        let habit = makeHabit()
        let date = Date.now
        sut.skipDate(date, for: habit)
        #expect(habit.isSkipped(on: date) == true)
    }
    
    @Test("Unskip date — removes from skippedDates")
    func unskipDate_removesFromSkippedDates() {
        let habit = makeHabit()
        let date = Date.now
        sut.skipDate(date, for: habit)
        sut.unskipDate(date, for: habit)
        #expect(habit.isSkipped(on: date) == false)
    }
    
    // MARK: - archive / delete
    
    @Test("Archive habit — sets isArchived to true")
    func archiveHabit_setsIsArchivedTrue() {
        let habit = makeHabit()
        sut.archive(habit)
        #expect(habit.isArchived == true)
    }
    
    @Test("Unarchive habit — sets isArchived to false")
    func unarchiveHabit_setsIsArchivedFalse() {
        let habit = makeHabit()
        sut.archive(habit)
        sut.unarchive(habit)
        #expect(habit.isArchived == false)
    }
    
    @Test("Delete habit — calls dataSource delete")
    func deleteHabit_callsDataSourceDelete() {
        let habit = makeHabit()
        sut.delete(habit)
        #expect(dataSource.deleteHabitCallCount == 1)
    }
    
    // MARK: - save
    
    @Test("Complete habit — calls save on dataSource")
    func completeHabit_callsSave() {
        let habit = makeHabit(goal: 1)
        sut.completeHabit(for: habit, date: .now)
        #expect(dataSource.saveCallCount > 0)
    }
    
    @Test("Complete habit — calls widget reload")
    func completeHabit_reloadsWidget() {
        let habit = makeHabit(goal: 1)
        sut.completeHabit(for: habit, date: .now)
        #expect(widgetService.reloadAfterDataChangeCallCount > 0)
    }
}
