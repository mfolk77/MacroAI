// PantryPlannerTests.swift
import Foundation
import SwiftData
import Testing
@testable import MacroAI_Pro

@MainActor
struct PantryPlannerTests {

    @Test func dryRunShoppingList_pure_noCrash() async throws {
        let mealNames = ["Chicken Bowl", "Oats"]
        let pantry: [String:(qty: Double, unit: String)] = ["rice": (qty: 200, unit: "g")]
        let list = PantryPlanner.dryRunShoppingList(for: mealNames, pantryStock: pantry)
        #expect(list.count >= 0)
    }
}


