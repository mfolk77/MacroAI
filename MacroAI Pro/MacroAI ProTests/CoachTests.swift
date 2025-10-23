import XCTest
@testable import MacroAI_Pro

@MainActor
final class CoachTests: XCTestCase {

    override func setUp() async throws {
        // Reset trial data
        CoachTrialManager.shared.reset()
    }

    func testTrialStartsOnceAndCountsDown() throws {
        XCTAssertFalse(CoachTrialManager.shared.isWithinTrialWindow())
        let started = CoachTrialManager.shared.startIfNeeded(days: 7)
        XCTAssertTrue(started)
        XCTAssertTrue(CoachTrialManager.shared.isWithinTrialWindow(days: 7))
        let remaining = CoachTrialManager.shared.daysRemaining()
        XCTAssertGreaterThanOrEqual(remaining, 0)
        // Second start should be no-op
        let startedAgain = CoachTrialManager.shared.startIfNeeded(days: 7)
        XCTAssertFalse(startedAgain)
    }

    func testQuietHours() throws {
        // 23h and 2h are quiet, 12h is not
        XCTAssertTrue(CoachEngine.shared._isQuietHour(hour: 23))
        XCTAssertTrue(CoachEngine.shared._isQuietHour(hour: 2))
        XCTAssertFalse(CoachEngine.shared._isQuietHour(hour: 12))
    }

    func testDedupeTwoHours() throws {
        let id = "unittest_dedupe"
        let now = Date()
        CoachEngine.shared._setLastScheduled(identifier: id, date: now)
        // Immediately after, should not allow within 2h
        XCTAssertFalse(CoachEngine.shared._canScheduleForTest(identifier: id, minInterval: 7200))
        // After 2h + 1s, should allow
        let twoHoursAgo = now.addingTimeInterval(-7201)
        CoachEngine.shared._setLastScheduled(identifier: id, date: twoHoursAgo)
        XCTAssertTrue(CoachEngine.shared._canScheduleForTest(identifier: id, minInterval: 7200))
    }
}


