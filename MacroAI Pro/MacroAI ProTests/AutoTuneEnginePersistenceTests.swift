// AutoTuneEnginePersistenceTests.swift
import Foundation
import SwiftData
import Testing
@testable import MacroAI_Pro

@MainActor
struct AutoTuneEnginePersistenceTests {
    @Test func seed_creates_persisted_record() async throws {
        // In-memory model context
        let container = try ModelContainer(
            for: MacroEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Ensure eligibility
        let sub = SubscriptionManager.shared
        let originalTier = sub.currentTier
        defer { sub.currentTier = originalTier }
        sub.currentTier = .pro

        // Clear existing records
        let defaults = UserDefaults.standard
        let oldData = defaults.object(forKey: "autotune_records_v1")
        defer {
            if let oldData = oldData { defaults.set(oldData, forKey: "autotune_records_v1") } else { defaults.removeObject(forKey: "autotune_records_v1") }
        }
        defaults.removeObject(forKey: "autotune_records_v1")

        // Seed a record (DEBUG only path persists a record)
        await AutoTuneEngine.shared.seedDebugRecordIfMissing(modelContext: context)

        // Assert persistence
        let records = AutoTuneEngine.shared.loadRecords()
        #expect(records.count >= 1)
        #expect(AutoTuneEngine.shared.lastRecord() != nil)
        #expect(AutoTuneEngine.shared.lastAdjustmentDeltaPercent() != nil)
    }
}
