// FoodVisionService.swift
// AI-powered food recognition service using OpenAI Vision API

import Foundation
import UIKit

// MARK: - Protocols

protocol FoodVisionServiceProtocol {
    func analyzeFoodImage(_ image: UIImage) async throws -> NutritionMacros
}

// MARK: - Production Implementation

class FoodVisionService: FoodVisionServiceProtocol {
    private let apiKey: String
    private let baseURL: URL
    
    init(apiKey: String, baseURL: URL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
    
    func analyzeFoodImage(_ image: UIImage) async throws -> NutritionMacros {
        print("🔍 [FoodVisionService] Analyzing food image...")
        
        // Step 1: Use OpenAI Vision to identify the food
        let foodName = try await identifyFoodWithOpenAI(image)
        
        // Step 2: Get nutrition data from USDA using identified food name
        let usdaClient = USDAFoodDatabase()
        let macros = try await usdaClient.getNutritionData(for: foodName)
        
        #if DEBUG
        print("✅ [FoodVisionService] Identified: \(foodName) → \(macros.calories) kcal")
        #endif
        
        return macros
    }
    
    private func identifyFoodWithOpenAI(_ image: UIImage) async throws -> String {
        // TODO: Implement actual OpenAI Vision API call
        // For now, return a mock food name
        print("🔍 [FoodVisionService] Mock OpenAI Vision analysis...")
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Mock food identification
        let mockFoods = ["chicken breast", "rice", "broccoli", "apple", "banana", "eggs"]
        return mockFoods.randomElement() ?? "chicken breast"
    }
}

// MARK: - Mock Implementation

class MockFoodVisionService: FoodVisionServiceProtocol {
    func analyzeFoodImage(_ image: UIImage) async throws -> NutritionMacros {
        print("🧪 [MockFoodVisionService] Mock food analysis")
        
        // Return consistent mock data
        return NutritionMacros(
            calories: 350,
            protein: 25,
            carbs: 45,
            fat: 12
        )
    }
} 