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
    
    init(apiKey: String, baseURL: URL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
    
    func getNutritionData(for foodName: String) async throws -> NutritionMacros {
        // For now, return mock data
        // TODO: Implement actual Spoonacular API call
        print("🍎 [NutritionService] Getting nutrition data for: \(foodName)")
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Return mock nutrition data
        return NutritionMacros(
            calories: Double.random(in: 100...600),
            protein: Double.random(in: 5...35),
            carbs: Double.random(in: 15...70),
            fat: Double.random(in: 3...25)
        )
    }
    
    func searchFood(_ query: String) async throws -> [String] {
        print("🔍 [NutritionService] Searching for: \(query)")
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Return mock search results
        return [
            "\(query) - Regular",
            "\(query) - Organic",
            "\(query) - Low Fat",
            "\(query) - High Protein"
        ]
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