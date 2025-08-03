// DietManager.swift
// Manages diet configurations and premium diet packs
import Foundation
import SwiftUI
internal import Combine

struct Diet: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let isPremium: Bool
    let macroDistribution: MacroDistribution
    let recommendations: DietRecommendations
    let guidelines: [String]
    let restrictedFoods: [String]?
    let recommendedFoods: [String]?
    let icon: String
    let primaryColor: Color
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, isPremium, macroDistribution, recommendations, guidelines, restrictedFoods, recommendedFoods, icon, primaryColor
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        isPremium = try container.decode(Bool.self, forKey: .isPremium)
        macroDistribution = try container.decode(MacroDistribution.self, forKey: .macroDistribution)
        recommendations = try container.decode(DietRecommendations.self, forKey: .recommendations)
        guidelines = try container.decode([String].self, forKey: .guidelines)
        restrictedFoods = try container.decodeIfPresent([String].self, forKey: .restrictedFoods)
        recommendedFoods = try container.decodeIfPresent([String].self, forKey: .recommendedFoods)
        icon = try container.decode(String.self, forKey: .icon)
        
        let colorString = try container.decode(String.self, forKey: .primaryColor)
        switch colorString {
        case "green":
            primaryColor = .green
        case "red":
            primaryColor = .red
        case "orange":
            primaryColor = .orange
        case "blue":
            primaryColor = .blue
        case "purple":
            primaryColor = .purple
        default:
            primaryColor = .green
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(isPremium, forKey: .isPremium)
        try container.encode(macroDistribution, forKey: .macroDistribution)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(guidelines, forKey: .guidelines)
        try container.encodeIfPresent(restrictedFoods, forKey: .restrictedFoods)
        try container.encodeIfPresent(recommendedFoods, forKey: .recommendedFoods)
        try container.encode(icon, forKey: .icon)
        
        let colorString: String
        switch primaryColor {
        case .green:
            colorString = "green"
        case .red:
            colorString = "red"
        case .orange:
            colorString = "orange"
        case .blue:
            colorString = "blue"
        case .purple:
            colorString = "purple"
        default:
            colorString = "green"
        }
        try container.encode(colorString, forKey: .primaryColor)
    }
    
    init(id: String, name: String, description: String, isPremium: Bool, macroDistribution: MacroDistribution, recommendations: DietRecommendations, guidelines: [String], restrictedFoods: [String]?, recommendedFoods: [String]?, icon: String, primaryColor: Color) {
        self.id = id
        self.name = name
        self.description = description
        self.isPremium = isPremium
        self.macroDistribution = macroDistribution
        self.recommendations = recommendations
        self.guidelines = guidelines
        self.restrictedFoods = restrictedFoods
        self.recommendedFoods = recommendedFoods
        self.icon = icon
        self.primaryColor = primaryColor
    }
    
    struct MacroDistribution: Codable {
        let protein: Int // percentage
        let carbs: Int   // percentage
        let fats: Int    // percentage
        
        var isValid: Bool {
            protein + carbs + fats == 100
        }
    }
    
    struct DietRecommendations: Codable {
        let dailyCalories: Int
        let mealsPerDay: Int
        let snacksPerDay: Int
        let maxNetCarbs: Int?
        let maxCarbsPerMeal: Int?
        let minProteinGrams: Int?
        let maxMealSize: String?
    }
}

struct DietRecipe: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let prepTime: String
    let servings: Int
    let macros: DietRecipeMacros
    let ingredients: [String]
    let difficulty: String
    
    struct DietRecipeMacros: Codable {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fats: Int
        let netCarbs: Int?
    }
}

struct DietRecipes: Codable {
    let dietId: String
    let recipes: [DietRecipe]
}

@MainActor
class DietManager: ObservableObject {
    @Published var availableDiets: [Diet] = []
    @Published var currentDiet: Diet
    @Published var dietRecipes: [String: [DietRecipe]] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let currentDietKey = "selectedDiet"
    
    init() {
        // Initialize with standard diet
        self.currentDiet = Diet(
            id: "standard",
            name: "Standard Diet",
            description: "Balanced nutrition",
            isPremium: false,
            macroDistribution: Diet.MacroDistribution(protein: 25, carbs: 45, fats: 30),
            recommendations: Diet.DietRecommendations(
                dailyCalories: 2000,
                mealsPerDay: 3,
                snacksPerDay: 2,
                maxNetCarbs: nil,
                maxCarbsPerMeal: nil,
                minProteinGrams: nil,
                maxMealSize: nil
            ),
            guidelines: ["Balanced nutrition for general health"],
            restrictedFoods: [],
            recommendedFoods: [],
            icon: "leaf.fill",
            primaryColor: .green
        )
        
        loadDiets()
        loadSavedDiet()
        loadRecipes()
    }
    
    // MARK: - Diet Loading
    
    private func loadDiets() {
        let dietFiles = ["standard", "keto", "diabetic", "gastric_bypass", "gastric_sleeve", "carnivore", "intermittent_fasting", "summer_beach_body"]
        var diets: [Diet] = []
        
        for dietFile in dietFiles {
            if let diet = loadDiet(from: dietFile) {
                diets.append(diet)
            }
        }
        
        self.availableDiets = diets
        print("✅ [DietManager] Loaded \(diets.count) diets")
    }
    
    private func loadDiet(from fileName: String) -> Diet? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let diet = try? JSONDecoder().decode(Diet.self, from: data) else {
            print("❌ [DietManager] Failed to load diet: \(fileName)")
            return nil
        }
        
        // Validate macro distribution
        guard diet.macroDistribution.isValid else {
            print("❌ [DietManager] Invalid macro distribution for diet: \(fileName)")
            return nil
        }
        
        return diet
    }
    
    // MARK: - Recipe Loading
    
    private func loadRecipes() {
        let recipeFiles = ["keto_recipes"]
        
        for recipeFile in recipeFiles {
            if let recipes = loadRecipeFile(from: recipeFile) {
                dietRecipes[recipes.dietId] = recipes.recipes
            }
        }
        
        print("✅ [DietManager] Loaded recipes for \(dietRecipes.keys.count) diets")
    }
    
    private func loadRecipeFile(from fileName: String) -> DietRecipes? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let recipes = try? JSONDecoder().decode(DietRecipes.self, from: data) else {
            print("❌ [DietManager] Failed to load recipes: \(fileName)")
            return nil
        }
        
        return recipes
    }
    
    // MARK: - Diet Selection
    
    func selectDiet(_ diet: Diet) {
        self.currentDiet = diet
        saveDiet()
        
        // Update MacroTargets with new percentages
        updateMacroTargets()
        
        print("✅ [DietManager] Selected diet: \(diet.name)")
    }
    
    private func saveDiet() {
        if let encoded = try? JSONEncoder().encode(currentDiet) {
            userDefaults.set(encoded, forKey: currentDietKey)
        }
    }
    
    private func loadSavedDiet() {
        guard let data = userDefaults.data(forKey: currentDietKey),
              let diet = try? JSONDecoder().decode(Diet.self, from: data) else {
            return
        }
        
        self.currentDiet = diet
        updateMacroTargets()
    }
    
    // MARK: - Macro Target Calculation
    
    private func updateMacroTargets() {
        let calories = Double(currentDiet.recommendations.dailyCalories)
        let proteinPercent = Double(currentDiet.macroDistribution.protein) / 100.0
        let carbPercent = Double(currentDiet.macroDistribution.carbs) / 100.0
        let fatPercent = Double(currentDiet.macroDistribution.fats) / 100.0
        
        // Calculate grams (protein: 4 cal/g, carbs: 4 cal/g, fats: 9 cal/g)
        let proteinGrams = (calories * proteinPercent) / 4.0
        let carbGrams = (calories * carbPercent) / 4.0
        let fatGrams = (calories * fatPercent) / 9.0
        
        let newTargets = MacroTargets(
            protein: proteinGrams,
            fats: fatGrams,
            carbs: carbGrams
        )
        newTargets.save()
        
        print("✅ [DietManager] Updated targets - P: \(Int(proteinGrams))g, C: \(Int(carbGrams))g, F: \(Int(fatGrams))g")
    }
    
    // MARK: - Recipe Access
    
    func getRecipes(for dietId: String) -> [DietRecipe] {
        return dietRecipes[dietId] ?? []
    }
    
    func getCurrentDietRecipes() -> [DietRecipe] {
        return getRecipes(for: currentDiet.id)
    }
    
    // MARK: - Premium Access
    
    func isPremiumDiet(_ diet: Diet) -> Bool {
        return diet.isPremium
    }
    
    func getAvailableDiets(isPremium: Bool) -> [Diet] {
        if isPremium {
            return availableDiets
        } else {
            return availableDiets.filter { !$0.isPremium }
        }
    }
}

// MARK: - Extensions

extension DietManager {
    static let shared = DietManager()
    
    static var preview: DietManager {
        let manager = DietManager()
        return manager
    }
}

// MARK: - Diet Extensions

extension Diet {
    // Additional computed properties can be added here if needed
}