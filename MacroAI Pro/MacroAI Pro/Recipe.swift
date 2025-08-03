// Recipe.swift
// Recipe management system with Spoonacular integration
import Foundation
import SwiftData
internal import Combine
import SwiftUI

@Model
class Recipe {
    @Attribute(.unique) var id: UUID
    var name: String
    var ingredients: [String]
    var instructions: [String]
    var servings: Int
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    
    // Nutrition per serving
    var caloriesPerServing: Int
    var proteinPerServing: Int
    var carbsPerServing: Int
    var fatsPerServing: Int
    
    // Metadata
    var dateCreated: Date
    var lastUsed: Date?
    var useCount: Int
    var tags: [String] // e.g., ["vegetarian", "quick", "healthy"]
    var notes: String?
    var imageData: Data?
    
    // Recipe source
    var source: RecipeSource
    var spoonacularID: Int? // If sourced from Spoonacular
    
    init(
        id: UUID = UUID(),
        name: String,
        ingredients: [String] = [],
        instructions: [String] = [],
        servings: Int = 1,
        prepTimeMinutes: Int? = nil,
        cookTimeMinutes: Int? = nil,
        caloriesPerServing: Int,
        proteinPerServing: Int,
        carbsPerServing: Int,
        fatsPerServing: Int,
        dateCreated: Date = Date(),
        useCount: Int = 0,
        tags: [String] = [],
        notes: String? = nil,
        imageData: Data? = nil,
        source: RecipeSource = .userCreated,
        spoonacularID: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.ingredients = ingredients
        self.instructions = instructions
        self.servings = servings
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.caloriesPerServing = caloriesPerServing
        self.proteinPerServing = proteinPerServing
        self.carbsPerServing = carbsPerServing
        self.fatsPerServing = fatsPerServing
        self.dateCreated = dateCreated
        self.useCount = useCount
        self.tags = tags
        self.notes = notes
        self.imageData = imageData
        self.source = source
        self.spoonacularID = spoonacularID
    }
    
    // Computed properties
    var totalTimeMinutes: Int? {
        guard let prep = prepTimeMinutes, let cook = cookTimeMinutes else { return nil }
        return prep + cook
    }
    
    var totalCalories: Int {
        caloriesPerServing * servings
    }
    
    var formattedIngredients: String {
        ingredients.joined(separator: "\n")
    }
    
    var formattedInstructions: String {
        instructions.enumerated().map { item in "\\(item.offset + 1). \\(item.element)" }.joined(separator: "\n\n")
    }
}

enum RecipeSource: String, Codable, CaseIterable {
    case userCreated = "user_created"
    case manualEntry = "manual_entry"
    case spoonacularAPI = "spoonacular_api"
    case photoAnalysis = "photo_analysis"
    
    var displayName: String {
        switch self {
        case .userCreated: return "Custom Recipe"
        case .manualEntry: return "Manual Entry"
        case .spoonacularAPI: return "Spoonacular Recipe"
        case .photoAnalysis: return "Photo Analysis"
        }
    }
    
    var icon: String {
        switch self {
        case .userCreated: return "doc.text"
        case .manualEntry: return "pencil"
        case .spoonacularAPI: return "network"
        case .photoAnalysis: return "camera"
        }
    }
}

// MARK: - Recipe Manager

@MainActor
class RecipeManager: ObservableObject {
    private var modelContext: ModelContext
    
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var error: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Recipe CRUD Operations
    
    func fetchRecipes() async {
        isLoading = true
        error = nil
        
        do {
            let descriptor = FetchDescriptor<Recipe>(
                sortBy: [SortDescriptor(\Recipe.lastUsed, order: .reverse),
                        SortDescriptor(\Recipe.dateCreated, order: .reverse)]
            )
            recipes = try modelContext.fetch(descriptor)
            print("✅ [RecipeManager] Fetched \(recipes.count) recipes")
        } catch {
            print("❌ [RecipeManager] Failed to fetch recipes: \(error)")
            self.error = "Failed to load recipes"
        }
        
        isLoading = false
    }
    
    func saveRecipe(_ recipe: Recipe) async -> Bool {
        do {
            modelContext.insert(recipe)
            try modelContext.save()
            
            // Update local array
            recipes.insert(recipe, at: 0)
            
            print("✅ [RecipeManager] Saved recipe: \(recipe.name)")
            return true
        } catch {
            print("❌ [RecipeManager] Failed to save recipe: \(error)")
            self.error = "Failed to save recipe"
            return false
        }
    }
    
    func deleteRecipe(_ recipe: Recipe) async {
        do {
            modelContext.delete(recipe)
            try modelContext.save()
            
            recipes.removeAll { $0.id == recipe.id }
            print("✅ [RecipeManager] Deleted recipe: \(recipe.name)")
        } catch {
            print("❌ [RecipeManager] Failed to delete recipe: \(error)")
            self.error = "Failed to delete recipe"
        }
    }
    
    func updateRecipe(_ recipe: Recipe) async {
        do {
            try modelContext.save()
            await fetchRecipes() // Refresh the list
            print("✅ [RecipeManager] Updated recipe: \(recipe.name)")
        } catch {
            print("❌ [RecipeManager] Failed to update recipe: \(error)")
            self.error = "Failed to update recipe"
        }
    }
    
    // MARK: - Recipe Usage Tracking
    
    func markRecipeAsUsed(_ recipe: Recipe) async {
        recipe.lastUsed = Date()
        recipe.useCount += 1
        await updateRecipe(recipe)
    }
    
    // MARK: - Recipe Search and Filtering
    
    func searchRecipes(query: String) -> [Recipe] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return recipes
        }
        
        return recipes.filter { recipe in
            recipe.name.localizedCaseInsensitiveContains(query) ||
            recipe.ingredients.joined().localizedCaseInsensitiveContains(query) ||
            recipe.tags.joined().localizedCaseInsensitiveContains(query)
        }
    }
    
    func filterRecipes(by source: RecipeSource) -> [Recipe] {
        return recipes.filter { $0.source == source }
    }
    
    func getPopularRecipes(limit: Int = 10) -> [Recipe] {
        return recipes
            .filter { $0.useCount > 0 }
            .sorted { $0.useCount > $1.useCount }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Recipe Creation Helpers
    
    func createRecipeFromManualEntry(
        name: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fats: Int,
        servings: Int = 1,
        notes: String? = nil
    ) async -> Recipe {
        let recipe = Recipe(
            name: name,
            servings: servings,
            caloriesPerServing: calories / servings,
            proteinPerServing: protein / servings,
            carbsPerServing: carbs / servings,
            fatsPerServing: fats / servings,
            notes: notes,
            source: .manualEntry
        )
        
        _ = await saveRecipe(recipe)
        return recipe
    }
    
    // MARK: - Spoonacular Recipe Analysis
    
    func analyzeRecipe(
        title: String,
        ingredients: [String],
        instructions: [String] = [],
        servings: Int = 1
    ) async throws -> Recipe {
        guard SpoonacularRecipeAPI.hasValidAPIKey() else {
            throw RecipeAnalysisError.missingAPIKey
        }
        
        let analyzedNutrition = try await SpoonacularRecipeAPI.analyzeRecipe(
            ingredients: ingredients,
            instructions: instructions
        )
        
        let recipe = Recipe(
            name: title,
            ingredients: ingredients,
            instructions: instructions,
            servings: servings,
            caloriesPerServing: Int(analyzedNutrition.calories / Double(servings)),
            proteinPerServing: Int(analyzedNutrition.protein / Double(servings)),
            carbsPerServing: Int(analyzedNutrition.carbs / Double(servings)),
            fatsPerServing: Int(analyzedNutrition.fat / Double(servings)),
            source: .spoonacularAPI
        )
        
        _ = await saveRecipe(recipe)
        return recipe
    }
}

// MARK: - Error Types

enum RecipeAnalysisError: Error, LocalizedError {
    case missingAPIKey
    case apiError(String)
    case invalidIngredients
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Spoonacular API key not configured"
        case .apiError:
            return "Recipe analysis failed. Please try again."
        case .invalidIngredients:
            return "Please provide valid ingredients"
        case .networkError:
            return "Network connection failed. Please check your internet connection."
        }
    }
}

// MARK: - Sample Data

extension Recipe {
    static var sampleRecipes: [Recipe] {
        [
            Recipe(
                name: "Birds Eye Vegetables & Rice",
                ingredients: ["1 bag Birds Eye vegetable medley", "1 cup brown rice", "1 tbsp olive oil"],
                instructions: ["Cook rice according to package", "Steam vegetables", "Mix together with olive oil"],
                servings: 2,
                prepTimeMinutes: 5,
                cookTimeMinutes: 20,
                caloriesPerServing: 280,
                proteinPerServing: 8,
                carbsPerServing: 45,
                fatsPerServing: 6,
                tags: ["healthy", "quick", "vegetarian"]
            ),
            Recipe(
                name: "Protein Smoothie",
                ingredients: ["1 scoop protein powder", "1 banana", "1 cup almond milk", "1 tbsp peanut butter"],
                instructions: ["Add all ingredients to blender", "Blend until smooth"],
                servings: 1,
                prepTimeMinutes: 3,
                caloriesPerServing: 350,
                proteinPerServing: 25,
                carbsPerServing: 35,
                fatsPerServing: 12,
                tags: ["protein", "quick", "breakfast"]
            )
        ]
    }
} 
