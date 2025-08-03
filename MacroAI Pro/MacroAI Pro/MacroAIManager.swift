//
//  MacroAIManager.swift
//  MacroAI
//
//  Main manager for MacroAI app functionality

import Foundation
import SwiftUI
internal import Combine

class MacroAIManager: ObservableObject {
    @Published var isScanning = false
    @Published var currentFood: String = ""
    @Published var nutritionData: NutritionData?
    @Published var nutritionMacros: NutritionMacros?
    
    private let barcodeService: BarcodeService
    private let nutritionService: NutritionServiceProtocol
    private let foodVisionService: FoodVisionServiceProtocol
    
    init(foodVision: FoodVisionServiceProtocol, nutrition: NutritionServiceProtocol, barcode: BarcodeService) {
        self.foodVisionService = foodVision
        self.nutritionService = nutrition
        self.barcodeService = barcode
    }
    
    func scanBarcode(_ barcode: String) async {
        print("🔍 [MacroAIManager] Starting barcode scan for: \(barcode)")
        isScanning = true
        defer { isScanning = false }
        
        let nutrition = await barcodeService.lookupBarcode(barcode)
        await MainActor.run {
            self.nutritionData = nutrition
            if nutrition != nil {
                print("✅ [MacroAIManager] Nutrition data found: \(nutrition?.foodName ?? "Unknown")")
            } else {
                print("❌ [MacroAIManager] No nutrition data found for barcode: \(barcode)")
            }
        }
    }
    
    func analyzeFoodImage(_ image: UIImage) async {
        isScanning = true
        defer { isScanning = false }
        
        do {
            let macros = try await foodVisionService.analyzeFoodImage(image)
            await MainActor.run {
                self.nutritionMacros = macros
            }
        } catch {
            print("Food vision analysis error: \(error)")
        }
    }
    
    func getNutritionData(for foodName: String) async {
        do {
            let macros = try await nutritionService.getNutritionData(for: foodName)
            await MainActor.run {
                self.nutritionMacros = macros
            }
        } catch {
            print("Nutrition data error: \(error)")
        }
    }
}

// Note: Protocols and implementations are now in separate service files
// - NutritionServiceProtocol and NutritionService in NutritionService.swift
// - FoodVisionServiceProtocol and FoodVisionService in FoodVisionService.swift
// - StoreKitManager in StoreKitManager.swift 