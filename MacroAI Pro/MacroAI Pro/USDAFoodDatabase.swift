// USDAFoodDatabase.swift
// Free USDA Food Database API client - replaces Spoonacular
// No API key required, high-quality nutrition data

import Foundation

// MARK: - USDA API Response Models

struct USDASearchResponse: Codable {
    let foods: [USDAFoodItem]
    let totalHits: Int
    let currentPage: Int
    let totalPages: Int
}

struct USDAFoodItem: Codable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let ingredients: String?
    let foodNutrients: [USDAFoodNutrient]?
    
    enum CodingKeys: String, CodingKey {
        case fdcId
        case description
        case brandOwner
        case ingredients
        case foodNutrients
    }
}

struct USDAFoodNutrient: Codable {
    let nutrient: USDANutrient
    let amount: Double
}

struct USDANutrient: Codable {
    let id: Int
    let name: String
    let unitName: String
}

// MARK: - USDA Food Database Client

class USDAFoodDatabase {
    private let baseURL = "https://api.nal.usda.gov/fdc/v1"
    private let apiKey = "DEMO_KEY" // Free tier, no registration required
    
    // MARK: - Food Search
    
    func searchFood(_ query: String) async throws -> [USDAFoodItem] {
        guard let url = URL(string: "\(baseURL)/foods/search") else {
            throw USDAError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "pageSize", value: "10"),
            URLQueryItem(name: "dataType", value: "Foundation,SR Legacy")
        ]
        
        guard let finalURL = components.url else {
            throw USDAError.invalidURL
        }
        
        #if DEBUG
        print("🔍 [USDAFoodDatabase] Searching for: \(query)")
        #endif
        
        let (data, response) = try await URLSession.shared.data(from: finalURL)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw USDAError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ [USDAFoodDatabase] API error: \(httpResponse.statusCode)")
            throw USDAError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let searchResponse = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        
        #if DEBUG
        print("✅ [USDAFoodDatabase] Found \(searchResponse.foods.count) results for: \(query)")
        #endif
        
        return searchResponse.foods
    }
    
    // MARK: - Nutrition Data
    
    func getNutritionData(for foodName: String) async throws -> NutritionMacros {
        // Search for the food first
        let searchResults = try await searchFood(foodName)
        
        guard let bestMatch = searchResults.first else {
            throw USDAError.notFound
        }
        
        // Get detailed nutrition data
        return try await getNutritionData(for: bestMatch.fdcId)
    }
    
    func getNutritionData(for foodId: Int) async throws -> NutritionMacros {
        guard let url = URL(string: "\(baseURL)/food/\(foodId)") else {
            throw USDAError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "nutrients", value: "203,204,205,208") // Protein, Fat, Carbs, Energy
        ]
        
        guard let finalURL = components.url else {
            throw USDAError.invalidURL
        }
        
        #if DEBUG
        print("🔍 [USDAFoodDatabase] Getting nutrition for food ID: \(foodId)")
        #endif
        
        let (data, response) = try await URLSession.shared.data(from: finalURL)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw USDAError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ [USDAFoodDatabase] Nutrition API error: \(httpResponse.statusCode)")
            throw USDAError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let foodDetail = try JSONDecoder().decode(USDAFoodItem.self, from: data)
        
        // Extract nutrition values
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        
        for nutrient in foodDetail.foodNutrients ?? [] {
            switch nutrient.nutrient.id {
            case 208: // Energy (kcal)
                calories = nutrient.amount
            case 203: // Protein
                protein = nutrient.amount
            case 205: // Carbohydrates
                carbs = nutrient.amount
            case 204: // Fat
                fat = nutrient.amount
            default:
                break
            }
        }
        
        #if DEBUG
        print("✅ [USDAFoodDatabase] Nutrition: \(calories) kcal, \(protein)g protein, \(carbs)g carbs, \(fat)g fat")
        #endif
        
        return NutritionMacros(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
    }
    
    // MARK: - Food Search Results (for autocomplete)
    
    func searchFoodNames(_ query: String) async throws -> [String] {
        let results = try await searchFood(query)
        return results.map { $0.description }
    }
}

// MARK: - USDA Errors

enum USDAError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case notFound
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid USDA API URL"
        case .invalidResponse:
            return "Invalid response from USDA API"
        case .apiError(let message):
            return "USDA API error: \(message)"
        case .notFound:
            return "Food not found in USDA database"
        case .decodingError:
            return "Failed to decode USDA response"
        }
    }
}
