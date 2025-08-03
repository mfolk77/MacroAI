// SpoonacularRecipeAPI.swift
// Recipe analysis using Spoonacular API

import Foundation

class SpoonacularRecipeAPI {
    private static let baseURL = URL(string: "https://api.spoonacular.com")!
    
    // MARK: - API Key Management
    
    static func saveAPIKey(_ key: String) {
        do {
            try SecureConfig.saveSpoonacularAPIKey(key)
        } catch {
            print("❌ Failed to save Spoonacular API key: \(error)")
        }
    }
    
    static func getAPIKey() -> String? {
        return SecureConfig.getSpoonacularAPIKey()
    }
    
    static func deleteAPIKey() {
        do {
            try SecureConfig.deleteSpoonacularAPIKey()
        } catch {
            print("❌ Failed to delete Spoonacular API key: \(error)")
        }
    }
    
    static func hasValidAPIKey() -> Bool {
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            return false
        }
        return true
    }
    
    // MARK: - Recipe Analysis
    
    static func analyzeRecipe(ingredients: [String], instructions: [String]) async throws -> NutritionMacros {
        print("🍳 [SpoonacularRecipeAPI] Analyzing recipe...")
        
        guard let apiKey = getAPIKey(), hasValidAPIKey() else {
            throw APIError.noAPIKey
        }
        
        // Make real Spoonacular API call for recipe analysis
        return try await makeSpoonacularRecipeAnalysisCall(ingredients: ingredients, instructions: instructions, apiKey: apiKey)
    }
    
    // MARK: - Real Spoonacular API Integration
    
    private static func makeSpoonacularRecipeAnalysisCall(ingredients: [String], instructions: [String], apiKey: String) async throws -> NutritionMacros {
        let url = URL(string: "https://api.spoonacular.com/recipes/analyze")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let ingredientsText = ingredients.joined(separator: "\n")
        let instructionsText = instructions.joined(separator: "\n")
        
        let requestBody: [String: Any] = [
            "title": "Recipe Analysis",
            "ingredients": ingredientsText,
            "instructions": instructionsText
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Add API key as query parameter
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "apiKey", value: apiKey)]
        request.url = urlComponents.url
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Spoonacular API Error: \(httpResponse.statusCode)")
            if let errorData = String(data: data, encoding: .utf8) {
                print("Error details: \(errorData)")
            }
            throw APIError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Extract nutrition data from Spoonacular response
        guard let nutrition = json?["nutrition"] as? [String: Any],
              let nutrients = nutrition["nutrients"] as? [[String: Any]] else {
            throw APIError.decodingError
        }
        
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        
        for nutrient in nutrients {
            guard let name = nutrient["name"] as? String,
                  let amount = nutrient["amount"] as? Double else { continue }
            
            switch name.lowercased() {
            case "calories":
                calories = amount
            case "protein":
                protein = amount
            case "carbohydrates":
                carbs = amount
            case "fat":
                fat = amount
            default:
                break
            }
        }
        
        return NutritionMacros(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
    }
    
    // MARK: - Recipe Search
    
    static func searchRecipes(query: String, diet: String? = nil, cuisine: String? = nil) async throws -> [Recipe] {
        print("🔍 [SpoonacularRecipeAPI] Searching recipes for: \(query)")
        
        guard let apiKey = getAPIKey(), hasValidAPIKey() else {
            throw APIError.noAPIKey
        }
        
        // Make real Spoonacular API call for recipe search
        return try await makeSpoonacularRecipeSearchCall(query: query, diet: diet, cuisine: cuisine, apiKey: apiKey)
    }
    
    private static func makeSpoonacularRecipeSearchCall(query: String, diet: String?, cuisine: String?, apiKey: String) async throws -> [Recipe] {
        var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/complexSearch")!
        var queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "number", value: "10"),
            URLQueryItem(name: "addRecipeInformation", value: "true"),
            URLQueryItem(name: "fillIngredients", value: "true")
        ]
        
        if let diet = diet {
            queryItems.append(URLQueryItem(name: "diet", value: diet))
        }
        
        if let cuisine = cuisine {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Spoonacular Search API Error: \(httpResponse.statusCode)")
            if let errorData = String(data: data, encoding: .utf8) {
                print("Error details: \(errorData)")
            }
            throw APIError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let results = json?["results"] as? [[String: Any]] else {
            throw APIError.decodingError
        }
        
        var recipes: [Recipe] = []
        
        for result in results {
            guard let id = result["id"] as? Int,
                  let title = result["title"] as? String,
                  let servings = result["servings"] as? Int,
                  let nutrition = result["nutrition"] as? [String: Any],
                  let nutrients = nutrition["nutrients"] as? [[String: Any]] else {
                continue
            }
            
            // Extract ingredients
            let ingredients = (result["extendedIngredients"] as? [[String: Any]])?.compactMap { ingredient in
                ingredient["original"] as? String
            } ?? []
            
            // Extract instructions
            let analyzedInstructions = result["analyzedInstructions"] as? [[String: Any]]
            let instructions = analyzedInstructions?.first?["steps"] as? [[String: Any]]
            let steps = instructions?.compactMap { step in
                step["step"] as? String
            } ?? []
            
            // Extract nutrition data
            var calories: Double = 0
            var protein: Double = 0
            var carbs: Double = 0
            var fat: Double = 0
            
            for nutrient in nutrients {
                guard let name = nutrient["name"] as? String,
                      let amount = nutrient["amount"] as? Double else { continue }
                
                switch name.lowercased() {
                case "calories":
                    calories = amount
                case "protein":
                    protein = amount
                case "carbohydrates":
                    carbs = amount
                case "fat":
                    fat = amount
                default:
                    break
                }
            }
            
            let recipe = Recipe(
                name: title,
                ingredients: ingredients,
                instructions: steps,
                servings: servings,
                caloriesPerServing: Int(calories / Double(servings)),
                proteinPerServing: Int(protein / Double(servings)),
                carbsPerServing: Int(carbs / Double(servings)),
                fatsPerServing: Int(fat / Double(servings)),
                tags: [],
                source: .spoonacularAPI
            )
            
            recipes.append(recipe)
        }
        
        return recipes
    }
    
    // MARK: - Recipe Details
    
    static func getRecipeDetails(id: Int) async throws -> Recipe {
        print("📋 [SpoonacularRecipeAPI] Getting recipe details for ID: \(id)")
        
        // For now, return mock data
        // TODO: Implement actual Spoonacular recipe details API call
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return Recipe(
            name: "Mock Recipe \(id)",
            ingredients: ["Mock Ingredient 1", "Mock Ingredient 2", "Mock Ingredient 3"],
            instructions: ["Mock Step 1", "Mock Step 2", "Mock Step 3"],
            servings: 6,
            caloriesPerServing: 400,
            proteinPerServing: 30,
            carbsPerServing: 50,
            fatsPerServing: 15,
            tags: ["mock", "detailed"],
            source: .spoonacularAPI
        )
    }
    
    // MARK: - Errors
    
    enum APIError: Error, LocalizedError {
        case noAPIKey
        case invalidURL
        case invalidResponse
        case decodingError
        case networkError
        case noDataFound
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "Spoonacular API key not configured"
            case .invalidURL:
                return "Invalid recipe API URL"
            case .invalidResponse:
                return "Invalid response from recipe API"
            case .decodingError:
                return "Failed to decode recipe data"
            case .networkError:
                return "Network error occurred"
            case .noDataFound:
                return "No recipe data found"
            case .apiError(let message):
                return "API Error: \(message)"
            }
        }
    }
} 