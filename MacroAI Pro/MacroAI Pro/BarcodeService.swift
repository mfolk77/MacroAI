// BarcodeService.swift
// Service for barcode lookup and nutrition data retrieval

import Foundation
internal import Combine

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
        
        // Strategy 1: Try Open Food Facts API (free, comprehensive)
        print("🔍 [BarcodeService] Trying Open Food Facts API...")
        if let nutritionData = try await lookupOpenFoodFacts(barcode) {
            print("✅ [BarcodeService] Found data via Open Food Facts API")
            return nutritionData
        }
        
        // Strategy 2: Try USDA Food Database
        print("🔍 [BarcodeService] Trying USDA Food Database...")
        if let nutritionData = try await lookupUSDA(barcode) {
            print("✅ [BarcodeService] Found data via USDA API")
            return nutritionData
        }
        
        // Strategy 3: Try Spoonacular API (if available)
        print("🔍 [BarcodeService] Trying Spoonacular API...")
        if let nutritionData = try await lookupSpoonacular(barcode) {
            print("✅ [BarcodeService] Found data via Spoonacular API")
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
    
    // MARK: - USDA Food Database
    
    private func lookupUSDA(_ barcode: String) async throws -> NutritionData? {
        // USDA doesn't have direct barcode lookup, but we can try searching by name
        // This is a fallback strategy
        return nil
    }
    
    // MARK: - Spoonacular API
    
    private func lookupSpoonacular(_ barcode: String) async throws -> NutritionData? {
        // Try to use existing SpoonacularAPI if available
        // This would require extending the existing SpoonacularAPI
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