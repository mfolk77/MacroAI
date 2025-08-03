// SpoonacularAPI.swift
// Spoonacular API client for nutrition data

import Foundation

// MARK: - API Response Models

struct SpoonacularSearchResponse: Codable {
    let searchResults: [SpoonacularSearchResult]
    let offset: Int
    let number: Int
    let totalResults: Int
}

struct SpoonacularSearchResult: Codable {
    let id: Int
    let title: String
    let image: String?
}

struct SpoonacularNutritionResponse: Codable {
    let nutrition: SpoonacularNutrition
}

struct SpoonacularNutrition: Codable {
    let nutrients: [SpoonacularNutrient]
}

struct SpoonacularNutrient: Codable {
    let name: String
    let amount: Double
    let unit: String
}

class SpoonacularAPI {
    private let apiKey: String
    private let baseURL: URL
    
    init(apiKey: String, baseURL: URL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
    
    // MARK: - API Methods
    
    func searchFood(_ query: String) async throws -> [FoodSearchResult] {
        var components = URLComponents(url: baseURL.appendingPathComponent("food/search"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "number", value: "10")
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        do {
            let searchResponse = try JSONDecoder().decode(SpoonacularSearchResponse.self, from: data)
            return searchResponse.searchResults.map { result in
                FoodSearchResult(
                    id: result.id,
                    title: result.title,
                    image: result.image ?? ""
                )
            }
        } catch {
            print("Failed to decode search response: \(error)")
            throw APIError.decodingError
        }
    }
    
    func getNutritionInfo(for foodId: Int) async throws -> NutritionInfo {
        var components = URLComponents(url: baseURL.appendingPathComponent("food/\(foodId)/information"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        do {
            let nutritionResponse = try JSONDecoder().decode(SpoonacularNutritionResponse.self, from: data)
            return parseNutritionInfo(from: nutritionResponse, foodId: foodId)
        } catch {
            print("Failed to decode nutrition response: \(error)")
            throw APIError.decodingError
        }
    }
    
    private func parseNutritionInfo(from response: SpoonacularNutritionResponse, foodId: Int) -> NutritionInfo {
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        
        for nutrient in response.nutrition.nutrients {
            switch nutrient.name.lowercased() {
            case "calories":
                calories = nutrient.amount
            case "protein":
                protein = nutrient.amount
            case "carbohydrates":
                carbs = nutrient.amount
            case "fat":
                fat = nutrient.amount
            default:
                break
            }
        }
        
        return NutritionInfo(
            id: foodId,
            title: "Food Item",
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
    }
    
    // MARK: - Data Models
    
    struct FoodSearchResult {
        let id: Int
        let title: String
        let image: String
    }
    
    struct NutritionInfo {
        let id: Int
        let title: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
    }
    
    enum APIError: Error {
        case invalidURL
        case invalidResponse
        case decodingError
        case networkError
    }
} 