// AppleVisionFoodService.swift
// Free on-device food recognition using Apple Vision Framework
// Replaces OpenAI Vision API - no API keys, no costs, privacy-first

import Foundation
import UIKit
import Vision
import CoreML

// MARK: - Apple Vision Food Recognition Service

class AppleVisionFoodService: FoodVisionServiceProtocol {
    
    func analyzeFoodImage(_ image: UIImage) async throws -> NutritionMacros {
        print("🔍 [AppleVisionFoodService] Analyzing food image with Apple Vision...")
        
        // Step 1: Use Apple Vision to identify food items
        let foodItems = try await identifyFoodWithAppleVision(image)
        
        // Step 2: Get nutrition data from USDA for identified foods
        let usdaClient = USDAFoodDatabase()
        
        // For multiple foods, use the first one or combine nutrition
        guard let primaryFood = foodItems.first else {
            throw FoodRecognitionError.noFoodDetected
        }
        
        let macros = try await usdaClient.getNutritionData(for: primaryFood)
        
        #if DEBUG
        print("✅ [AppleVisionFoodService] Detected: \(foodItems.joined(separator: ", "))")
        print("✅ [AppleVisionFoodService] Primary: \(primaryFood) → \(macros.calories) kcal")
        #endif
        
        return macros
    }
    
    // MARK: - Apple Vision Food Detection
    
    private func identifyFoodWithAppleVision(_ image: UIImage) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: FoodRecognitionError.invalidImage)
                return
            }
            
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Filter for food-related classifications
                let foodItems = observations
                    .filter { $0.confidence > 0.3 } // Confidence threshold
                    .filter { AppleVisionFoodService.isFoodRelated($0.identifier) }
                    .sorted { $0.confidence > $1.confidence }
                    .prefix(3) // Top 3 food items
                    .map { $0.identifier }
                
                continuation.resume(returning: Array(foodItems))
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Food Classification Helper
    
    static func isFoodRelated(_ identifier: String) -> Bool {
        let foodKeywords = [
            "apple", "banana", "orange", "grape", "strawberry", "blueberry",
            "chicken", "beef", "pork", "fish", "salmon", "tuna", "shrimp",
            "bread", "pasta", "rice", "potato", "carrot", "broccoli", "lettuce",
            "cheese", "milk", "yogurt", "egg", "butter", "oil",
            "pizza", "burger", "sandwich", "salad", "soup", "pasta"
        ]
        
        let lowercased = identifier.lowercased()
        return foodKeywords.contains { lowercased.contains($0) }
    }
}

// MARK: - Enhanced Food Recognition (Optional)

class EnhancedAppleVisionFoodService: FoodVisionServiceProtocol {
    
    func analyzeFoodImage(_ image: UIImage) async throws -> NutritionMacros {
        print("🔍 [EnhancedAppleVisionFoodService] Enhanced food analysis...")
        
        // Try multiple Apple Vision approaches
        let approaches = [
            classifyWithImageClassification,
            detectWithObjectDetection,
            analyzeWithTextRecognition
        ]
        
        var allFoodItems: [String] = []
        
        for approach in approaches {
            do {
                let items = try await approach(image)
                allFoodItems.append(contentsOf: items)
            } catch {
                // Continue with other approaches
                continue
            }
        }
        
        // Remove duplicates and get primary food
        let uniqueFoods = Array(Set(allFoodItems))
        guard let primaryFood = uniqueFoods.first else {
            throw FoodRecognitionError.noFoodDetected
        }
        
        // Get nutrition data
        let usdaClient = USDAFoodDatabase()
        let macros = try await usdaClient.getNutritionData(for: primaryFood)
        
        #if DEBUG
        print("✅ [EnhancedAppleVisionFoodService] All detected: \(uniqueFoods.joined(separator: ", "))")
        print("✅ [EnhancedAppleVisionFoodService] Using: \(primaryFood)")
        #endif
        
        return macros
    }
    
    // MARK: - Multiple Recognition Approaches
    
    private func classifyWithImageClassification(_ image: UIImage) async throws -> [String] {
        // Use VNClassifyImageRequest (same as basic implementation)
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: FoodRecognitionError.invalidImage)
                return
            }
            
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let foodItems = observations
                    .filter { $0.confidence > 0.2 }
                    .filter { AppleVisionFoodService.isFoodRelated($0.identifier) }
                    .map { $0.identifier }
                
                continuation.resume(returning: foodItems)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectWithObjectDetection(_ image: UIImage) async throws -> [String] {
        // Placeholder for future object detection enhancement
        // For now, return empty array since object detection isn't food-specific
        return []
    }
    
    private func analyzeWithTextRecognition(_ image: UIImage) async throws -> [String] {
        // Use VNRecognizeTextRequest to find food names in text
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: FoodRecognitionError.invalidImage)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let textItems = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .filter { AppleVisionFoodService.isFoodRelated($0) }
                
                continuation.resume(returning: textItems)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    static func isFoodRelated(_ identifier: String) -> Bool {
        let foodKeywords = [
            "apple", "banana", "orange", "grape", "strawberry", "blueberry",
            "chicken", "beef", "pork", "fish", "salmon", "tuna", "shrimp",
            "bread", "pasta", "rice", "potato", "carrot", "broccoli", "lettuce",
            "cheese", "milk", "yogurt", "egg", "butter", "oil",
            "pizza", "burger", "sandwich", "salad", "soup", "pasta"
        ]
        
        let lowercased = identifier.lowercased()
        return foodKeywords.contains { lowercased.contains($0) }
    }
}

// MARK: - Errors

enum FoodRecognitionError: Error, LocalizedError {
    case invalidImage
    case noFoodDetected
    case visionError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .noFoodDetected:
            return "No food items detected in image"
        case .visionError(let message):
            return "Vision analysis error: \(message)"
        }
    }
}
