// CoachEngineStreakPersistenceTests.swift
import Foundation
import Testing
@testable import MacroAI_Pro

@MainActor
struct CoachEngineStreakPersistenceTests {
    @Test func streak_increments_once_per_day_and_persists() async throws {
        let defaults = UserDefaults.standard
        // Backup existing values
        let oldStreak = defaults.object(forKey: "currentStreak")
        let oldLastInc = defaults.object(forKey: "lastStreakIncrementDate")
        let oldLastEntry = defaults.object(forKey: "lastEntryDate")
        defer {
            if let v = oldStreak { defaults.set(v, forKey: "currentStreak") } else { defaults.removeObject(forKey: "currentStreak") }
            if let v = oldLastInc { defaults.set(v, forKey: "lastStreakIncrementDate") } else { defaults.removeObject(forKey: "lastStreakIncrementDate") }
            if let v = oldLastEntry { defaults.set(v, forKey: "lastEntryDate") } else { defaults.removeObject(forKey: "lastEntryDate") }
        }

        // Reset streak
        defaults.set(0, forKey: "currentStreak")
        defaults.removeObject(forKey: "lastStreakIncrementDate")
        defaults.removeObject(forKey: "lastEntryDate")

        // First action → increments to 1
        CoachEngine.shared.recordUserActionAndUpdateStreak()
        #expect(defaults.integer(forKey: "currentStreak") == 1)

        // Same-day second action → should not increment
        CoachEngine.shared.recordUserActionAndUpdateStreak()
        #expect(defaults.integer(forKey: "currentStreak") == 1)

        // Simulate new day
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        defaults.set(yesterday, forKey: "lastStreakIncrementDate")
        CoachEngine.shared.recordUserActionAndUpdateStreak()
        #expect(defaults.integer(forKey: "currentStreak") == 2)
    }
}
