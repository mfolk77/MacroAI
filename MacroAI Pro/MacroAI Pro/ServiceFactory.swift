// ServiceFactory.swift
// Production service factory that creates real service instances with API keys from Keychain
import Foundation
import UIKit

@MainActor
final class ServiceFactory {
    
    enum ServiceError: Error, LocalizedError {
        case missingOpenAIKey
        case missingSpoonacularKey
        case invalidConfiguration
        
        var errorDescription: String? {
            switch self {
            case .missingOpenAIKey:
                return "OpenAI API key not configured in SecureConfig.swift"
            case .missingSpoonacularKey:
                return "Spoonacular API key not configured in SecureConfig.swift"
            case .invalidConfiguration:
                return "Invalid service configuration."
            }
        }
    }
    
    // MARK: - Production Services
    
    static func createMacroAIManager() throws -> MacroAIManager {
        print("🏭 [ServiceFactory] Creating production MacroAI manager...")
        
        // Add null checks to prevent NSMapTable errors
        guard let foodVision = try? createFoodVisionService() else {
            throw ServiceError.invalidConfiguration
        }
        
        guard let nutrition = try? createNutritionService() else {
            throw ServiceError.invalidConfiguration
        }
        
        guard let barcode = try? createBarcodeService() else {
            throw ServiceError.invalidConfiguration
        }
        
        print("✅ [ServiceFactory] MacroAI manager created successfully")
        return MacroAIManager(foodVision: foodVision, nutrition: nutrition, barcode: barcode)
    }
    
    static func createFoodVisionService() throws -> FoodVisionServiceProtocol {
        // Try to get API key from Keychain using SecureConfig
        if let apiKey = SecureConfig.getOpenAIAPIKey() {
            let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
            return FoodVisionService(apiKey: apiKey, baseURL: baseURL)
        } else {
            throw ServiceError.missingOpenAIKey
        }
    }
    
    static func createNutritionService() throws -> NutritionServiceProtocol {
        // Try to get API key from Keychain using SecureConfig
        if let apiKey = SecureConfig.getSpoonacularAPIKey() {
            let baseURL = URL(string: "https://api.spoonacular.com")!
            return NutritionService(apiKey: apiKey, baseURL: baseURL)
        } else {
            return MockNutritionService()
        }
    }
    
    static func createBarcodeService() throws -> BarcodeService {
        // Add null check to prevent NSMapTable errors
        guard let nutritionService = try? createNutritionService() else {
            throw ServiceError.invalidConfiguration
        }
        let barcodeService = BarcodeService(nutritionService: nutritionService)
        return barcodeService
    }
    
    // MARK: - Development/Testing Services
    
    static func createMockMacroAIManager() -> MacroAIManager {
        print("🧪 [ServiceFactory] Creating mock MacroAI manager for development...")
        
        let foodVision = MockFoodVisionService()
        let nutrition = MockNutritionService()
        let barcode = BarcodeService(nutritionService: nutrition)
        
        return MacroAIManager(foodVision: foodVision, nutrition: nutrition, barcode: barcode)
    }
    
    // MARK: - API Key Management
    
    static func hasValidConfiguration() -> Bool {
        // Check if both API keys are configured in Keychain using SecureConfig
        let hasOpenAI = SecureConfig.getOpenAIAPIKey() != nil
        let hasSpoonacular = SecureConfig.getSpoonacularAPIKey() != nil
        
        return hasOpenAI && hasSpoonacular
    }
    
    static func saveOpenAIKey(_ key: String) {
        // Add null check to prevent errors
        guard !key.isEmpty else {
            print("❌ [ServiceFactory] Cannot save empty OpenAI key")
            return
        }
        
        do {
            try SecureConfig.saveOpenAIAPIKey(key)
        } catch {
            print("❌ [ServiceFactory] Failed to save OpenAI key: \(error)")
        }
    }
    
    static func saveSpoonacularKey(_ key: String) {
        // Add null check to prevent errors
        guard !key.isEmpty else {
            print("❌ [ServiceFactory] Cannot save empty Spoonacular key")
            return
        }
        
        do {
            try SecureConfig.saveSpoonacularAPIKey(key)
        } catch {
            print("❌ [ServiceFactory] Failed to save Spoonacular key: \(error)")
        }
    }
    
    static func clearAllKeys() {
        do {
            try SecureConfig.deleteOpenAIAPIKey()
            try SecureConfig.deleteSpoonacularAPIKey()
        } catch {
            print("❌ [ServiceFactory] Failed to clear keys: \(error)")
        }
    }

} 
