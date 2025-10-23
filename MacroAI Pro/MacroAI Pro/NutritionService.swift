// NutritionService.swift
// Nutrition data service using Spoonacular API

import Foundation

// MARK: - Protocols

protocol NutritionServiceProtocol {
    func getNutritionData(for foodName: String) async throws -> NutritionMacros
    func searchFood(_ query: String) async throws -> [String]
}

// MARK: - Production Implementation

class NutritionService: NutritionServiceProtocol {
    private let apiKey: String
    private let baseURL: URL
    
    private enum NutritionServiceError: Error {
        case noAPIKey
        case notFound
    }
    
    init(apiKey: String, baseURL: URL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
    
    func getNutritionData(for foodName: String) async throws -> NutritionMacros {
        #if DEBUG
        print("🍎 [NutritionService] Fetching nutrition via USDA for: \(foodName)")
        #endif
        
        let usdaClient = USDAFoodDatabase()
        let macros = try await usdaClient.getNutritionData(for: foodName)
        
        #if DEBUG
        print("🍎 [NutritionService] \(foodName) → kcal: \(macros.calories), P: \(macros.protein), C: \(macros.carbs), F: \(macros.fat)")
        #endif
        
        return macros
    }
    
    func searchFood(_ query: String) async throws -> [String] {
        #if DEBUG
        print("🔍 [NutritionService] Searching USDA for: \(query)")
        #endif
        
        let usdaClient = USDAFoodDatabase()
        return try await usdaClient.searchFoodNames(query)
    }
}

// MARK: - Mock Implementation

class MockNutritionService: NutritionServiceProtocol {
    func getNutritionData(for foodName: String) async throws -> NutritionMacros {
        print("🧪 [MockNutritionService] Mock nutrition data for: \(foodName)")
        
        // Return consistent mock data
        return NutritionMacros(
            calories: 250,
            protein: 15,
            carbs: 30,
            fat: 8
        )
    }
    
    func searchFood(_ query: String) async throws -> [String] {
        print("🧪 [MockNutritionService] Mock search for: \(query)")
        
        return [
            "Mock \(query)",
            "Test \(query)",
            "Sample \(query)"
        ]
    }
} 