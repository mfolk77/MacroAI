// SubscriptionGatingTests.swift
import Foundation
import Testing
@testable import MacroAI_Pro

@MainActor
struct SubscriptionGatingTests {
    @Test func basic_vs_premium_gates() async throws {
        let manager = SubscriptionManager.shared
        // Save current state
        let current = manager.currentTier
        defer { manager.currentTier = current }

        manager.currentTier = .basic
        #expect(!(manager.currentTier == .pro || manager.currentTier == .elite))

        manager.currentTier = .pro
        #expect(manager.currentTier == .pro)
    }
}


