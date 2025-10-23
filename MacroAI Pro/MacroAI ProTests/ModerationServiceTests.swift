// ModerationServiceTests.swift
import Foundation
import Testing
@testable import MacroAI_Pro

@MainActor
struct ModerationServiceTests {
    @Test func userPrompt_blockedAndAllowed() async throws {
        let svc = ModerationService.shared
        let blocked = svc.evaluateUserPrompt("how to get a fake id")
        #expect(blocked.isAllowed == false)
        let allowed = svc.evaluateUserPrompt("what are high protein breakfasts")
        #expect(allowed.isAllowed == true)
    }
}


