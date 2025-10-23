// BarcodeService.swift
// Service for barcode lookup and nutrition data retrieval

import Foundation
import Combine

@MainActor
class BarcodeService: ObservableObject {
    @Published var isSearching = false
    @Published var searchError: String?
    
    private let nutritionService: NutritionServiceProtocol
    private let cache = NSCache<NSString, NutritionData>()
    
    public init(nutritionService: NutritionServiceProtocol) {
        self.nutritionService = nutritionService
    }
    
    // MARK: - Barcode Lookup
    
    func lookupBarcode(_ barcode: String) async -> NutritionData? {
        print("🔍 [BarcodeService] Starting barcode lookup for: \(barcode)")
        isSearching = true
        searchError = nil
        
        // Check cache first
        if let cached = cache.object(forKey: barcode as NSString) {
            print("✅ [BarcodeService] Found cached data for barcode: \(barcode)")
            isSearching = false
            return cached
        }
        
        do {
            // Try multiple barcode lookup strategies
            let nutritionData = try await performBarcodeLookup(barcode)
            
            // Cache the result
            if let nutritionData = nutritionData {
                cache.setObject(nutritionData, forKey: barcode as NSString)
            }
            
            isSearching = false
            return nutritionData
            
        } catch {
            isSearching = false
            searchError = "Failed to lookup barcode: \(error.localizedDescription)"
            print("❌ [BarcodeService] Lookup failed for \(barcode): \(error)")
            return nil
        }
    }
    
    private func performBarcodeLookup(_ barcode: String) async throws -> NutritionData? {
        print("🔍 [BarcodeService] Starting barcode lookup for: \(barcode)")
        
        // Strategy 1: Open Food Facts → USDA (new primary flow)
        print("🔍 [BarcodeService] Trying Open Food Facts → USDA flow...")
        if let nutritionData = try await lookupOpenFoodFactsToUSDA(barcode) {
            print("✅ [BarcodeService] Found data via Open Food Facts → USDA")
            return nutritionData
        }
        
        // Strategy 2: Direct Open Food Facts (fallback)
        print("🔍 [BarcodeService] Open Food Facts → USDA failed; trying direct Open Food Facts...")
        if let nutritionData = try await lookupOpenFoodFacts(barcode) {
            print("✅ [BarcodeService] Found data via Open Food Facts API")
            return nutritionData
        }
        
        print("❌ [BarcodeService] No data found for barcode: \(barcode)")
        return nil
    }
    
    // MARK: - Open Food Facts API
    
    private func lookupOpenFoodFacts(_ barcode: String) async throws -> NutritionData? {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        print("🔍 [BarcodeService] Calling Open Food Facts API: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [BarcodeService] Invalid URL: \(urlString)")
            throw BarcodeServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [BarcodeService] Invalid HTTP response")
            throw BarcodeServiceError.networkError
        }
        
        print("🔍 [BarcodeService] Open Food Facts API response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ [BarcodeService] Open Food Facts API error: \(httpResponse.statusCode)")
            throw BarcodeServiceError.networkError
        }
        
        let decoder = JSONDecoder()
        let openFoodFactsResponse = try decoder.decode(OpenFoodFactsResponse.self, from: data)
        
        print("🔍 [BarcodeService] Open Food Facts response status: \(openFoodFactsResponse.status)")
        
        guard openFoodFactsResponse.status == 1,
              let product = openFoodFactsResponse.product else {
            print("❌ [BarcodeService] No product data found in Open Food Facts response")
            return nil
        }
        
        print("✅ [BarcodeService] Found product: \(product.productName ?? "Unknown")")
        return convertToNutritionData(product)
    }
    
    // MARK: - Open Food Facts → USDA Flow
    
    private func lookupOpenFoodFactsToUSDA(_ barcode: String) async throws -> NutritionData? {
        // Step 1: Get product name from Open Food Facts
        guard let productName = try await getProductNameFromOpenFoodFacts(barcode) else {
            return nil
        }
        
        // Step 2: Get nutrition data from USDA using product name
        let usdaClient = USDAFoodDatabase()
        do {
            let macros = try await usdaClient.getNutritionData(for: productName)
            
            #if DEBUG
            print("✅ [BarcodeService] Open Food Facts → USDA: \(productName)")
            #endif
            
            return NutritionData(
                foodName: productName,
                calories: macros.calories,
                protein: macros.protein,
                carbs: macros.carbs,
                fats: macros.fat,
                servingSize: 100,
                servingSizeType: "g",
                brand: nil,
                barcode: barcode
            )
        } catch {
            #if DEBUG
            print("❌ [BarcodeService] USDA lookup failed for \(productName): \(error)")
            #endif
            return nil
        }
    }
    
    private func getProductNameFromOpenFoodFacts(_ barcode: String) async throws -> String? {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            throw BarcodeServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BarcodeServiceError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            return nil
        }
        
        let decoder = JSONDecoder()
        let openFoodFactsResponse = try decoder.decode(OpenFoodFactsResponse.self, from: data)
        
        guard openFoodFactsResponse.status == 1,
              let product = openFoodFactsResponse.product,
              let productName = product.productName else {
            return nil
        }
        
        return productName
    }
    
    // MARK: - USDA Food Database (Direct)
    
    private func lookupUSDA(_ barcode: String) async throws -> NutritionData? {
        // USDA doesn't have direct barcode lookup, but we can try searching by name
        // This is a fallback strategy
        return nil
    }
    
    // MARK: - Spoonacular API (DEPRECATED - will be removed)
    
    private func lookupSpoonacular(_ barcode: String) async throws -> NutritionData? {
        // Spoonacular deprecated - return nil to force fallback to Open Food Facts
        return nil
    }
    
    // MARK: - Data Conversion
    
    private func convertToNutritionData(_ product: OpenFoodFactsProduct) -> NutritionData {
        let nutrition = product.nutriments ?? OpenFoodFactsNutriments(
            energyKcal: 0,
            proteins: 0,
            carbohydrates: 0,
            fat: 0,
            servingSize: 0
        )
        
        return NutritionData(
            foodName: product.productName ?? "Unknown Product",
            calories: nutrition.energyKcal ?? 0,
            protein: nutrition.proteins ?? 0,
            carbs: nutrition.carbohydrates ?? 0,
            fats: nutrition.fat ?? 0,
            servingSize: nutrition.servingSize ?? 100,
            servingSizeType: "g",
            brand: product.brands,
            barcode: product.code
        )
    }
}

// MARK: - Open Food Facts Models

struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let brands: String?
    let code: String?
    let nutriments: OpenFoodFactsNutriments?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case code
        case nutriments
    }
}

struct OpenFoodFactsNutriments: Codable {
    let energyKcal: Double?
    let proteins: Double?
    let carbohydrates: Double?
    let fat: Double?
    let servingSize: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g"
        case proteins = "proteins_100g"
        case carbohydrates = "carbohydrates_100g"
        case fat = "fat_100g"
        case servingSize = "serving_size"
    }
}

// MARK: - Nutrition Data Model

public class NutritionData {
    public let foodName: String
    public let calories: Double
    public let protein: Double
    public let carbs: Double
    public let fats: Double
    public let servingSize: Double
    public let servingSizeType: String
    public let brand: String?
    public let barcode: String?
    
    public init(foodName: String, calories: Double, protein: Double, carbs: Double, fats: Double, servingSize: Double, servingSizeType: String, brand: String?, barcode: String?) {
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.servingSize = servingSize
        self.servingSizeType = servingSizeType
        self.brand = brand
        self.barcode = barcode
    }
}

// MARK: - Errors

enum BarcodeServiceError: Error, LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    case noDataFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid barcode URL"
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Failed to decode response"
        case .noDataFound:
            return "No nutrition data found for this barcode"
        }
    }
} 