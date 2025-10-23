// CoachEngineTests.swift
import Foundation
import Testing
@testable import MacroAI_Pro

@MainActor
struct CoachEngineTests {
    @Test func schedule_noCrash_and_testNudge() async throws {
        // Start with eligibility true; should schedule without crash
        CoachEngine.shared.startIfEligible(isEligible: true)
        // Trigger a test nudge; not asserting delivery, only no-crash
        CoachEngine.shared.sendTestNudgeNow()
        #expect(true)
    }
}


