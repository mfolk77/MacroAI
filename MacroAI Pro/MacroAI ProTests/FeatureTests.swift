import XCTest
import SwiftData
@testable import MacroAI_Pro

@MainActor
final class FeatureTests: XCTestCase {
    func testCreateShoppingListPersistsAndSelectable() throws {
        let planner = PantryPlanner()
        let list = planner.createList(named: "Thanksgiving")
        XCTAssertEqual(list.name, "Thanksgiving")
        let fetched = planner.fetchLists()
        XCTAssertTrue(fetched.contains(where: { $0.id == list.id }))
    }

    func testNutritionContextSummaryIncludesPantryOrList() throws {
        let planner = PantryPlanner()
        planner.addOrUpdatePantryItem(name: "oats", unit: "g", qty: 100)
        _ = planner.createList(named: "This Week")
        let summary = planner.buildNutritionContextSummary()
        XCTAssertFalse(summary.isEmpty)
    }

    func testAppReviewOneTime() {
        let mgr = AppReviewManager.shared
        UserDefaults.standard.removeObject(forKey: "appreview.lastPromptDate")
        UserDefaults.standard.removeObject(forKey: "appreview.hasReviewed")
        XCTAssertTrue(mgr.shouldPromptNow())
        mgr.requestReviewIfAppropriate(in: nil) // no scene in tests
        XCTAssertFalse(mgr.shouldPromptNow())
    }

    func testDebugPremiumOverride() {
        #if DEBUG
        let sm = SubscriptionManager.shared
        sm.forcePremiumOverride(true)
        XCTAssertNotEqual(sm.currentTier, .basic)
        sm.forcePremiumOverride(false)
        XCTAssertEqual(sm.currentTier, .basic)
        #endif
    }
}


