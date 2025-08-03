// NutritionCache.swift
// Temporary storage for Spoonacular nutrition data with automatic expiry
import Foundation
import SwiftData
import SwiftUI
import UIKit

// MARK: - Nutrition Macros Structure
// Note: NutritionMacros is defined in MacroAIManager.swift

@Model
class NutritionCacheEntry {
    @Attribute(.unique) var id: UUID
    var foodName: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double
    var timestamp: Date
    var source: String // "spoonacular" vs "openai_estimate"
    
    // Computed property to check if entry is expired (1 hour)
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 3600 // 1 hour in seconds
    }
    
    init(
        id: UUID = UUID(),
        foodName: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fats: Double,
        timestamp: Date = Date(),
        source: String = "spoonacular"
    ) {
        self.id = id
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.timestamp = timestamp
        self.source = source
    }
}

// MARK: - Nutrition Cache Manager

@MainActor
class NutritionCacheManager {
    private var modelContext: ModelContext
    private var isSaving = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Set up background task for automatic cleanup
        Task {
            await scheduleAutomaticCleanup()
        }
    }
    
    /// Cache nutrition data temporarily (expires in 1 hour)
    func cacheNutrition(
        foodName: String,
        macros: NutritionMacros,
        source: String = "spoonacular"
    ) async {
        // Prevent concurrent saves
        guard !isSaving else {
            print("⚠️ [NutritionCache] Save operation in progress, skipping cache")
            return
        }
        
        // First check if we already have a recent entry for this food
        if let _ = await getCachedNutrition(for: foodName, allowExpired: false) {
            print("🗄️ [NutritionCache] Using existing cache for \(foodName)")
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        let entry = NutritionCacheEntry(
            foodName: foodName,
            calories: macros.calories,
            protein: macros.protein,
            carbs: macros.carbs,
            fats: macros.fat,
            source: source
        )
        
        do {
            modelContext.insert(entry)
            
            // Retry mechanism for save operations
            var retryCount = 0
            let maxRetries = 3
            
            while retryCount < maxRetries {
                do {
                    try modelContext.save()
                    break
                } catch {
                    retryCount += 1
                    print("❌ [NutritionCache] Save attempt \(retryCount) failed: \(error)")
                    
                    if retryCount >= maxRetries {
                        throw error
                    }
                    
                    try await Task.sleep(for: .milliseconds(100 * retryCount))
                }
            }
            
            print("💾 [NutritionCache] Cached nutrition for \(foodName) (expires in 1 hour)")
        } catch {
            print("❌ [NutritionCache] Failed to cache nutrition: \(error)")
            if error.localizedDescription.contains("BackingData") {
                print("🔄 [NutritionCache] BackingData encoding error - cache operation skipped")
            }
        }
    }
    
    /// Retrieve cached nutrition data if not expired
    func getCachedNutrition(for foodName: String, allowExpired: Bool = false) async -> NutritionMacros? {
        do {
            let descriptor = FetchDescriptor<NutritionCacheEntry>(
                predicate: #Predicate { $0.foodName.contains(foodName) },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            
            let entries = try modelContext.fetch(descriptor)
            
            if let entry = entries.first(where: { $0.foodName.compare(foodName, options: .caseInsensitive) == .orderedSame }) {
                if !entry.isExpired || allowExpired {
                    print("🎯 [NutritionCache] Found cached nutrition for \(foodName)")
                    return NutritionMacros(
                        calories: entry.calories,
                        protein: entry.protein,
                        carbs: entry.carbs,
                        fat: entry.fats
                    )
                } else {
                    print("⏰ [NutritionCache] Cache expired for \(foodName)")
                }
            }
        } catch {
            print("❌ [NutritionCache] Failed to fetch cached nutrition: \(error)")
        }
        
        return nil
    }
    
    /// Clean up expired nutrition cache entries
    func cleanupExpiredEntries() async {
        do {
            let descriptor = FetchDescriptor<NutritionCacheEntry>()
            let allEntries = try modelContext.fetch(descriptor)
            
            let expiredEntries = allEntries.filter { $0.isExpired }
            
            guard !expiredEntries.isEmpty else {
                print("✅ [NutritionCache] No expired entries to clean up")
                return
            }
            
            for entry in expiredEntries {
                modelContext.delete(entry)
            }
            
            try modelContext.save()
            print("🗑️ [NutritionCache] Cleaned up \(expiredEntries.count) expired nutrition entries")
            
        } catch {
            print("❌ [NutritionCache] Failed to cleanup expired entries: \(error)")
        }
    }
    
    /// Get cache statistics
    func getCacheStats() async -> (total: Int, expired: Int, totalSizeMB: Double) {
        do {
            let descriptor = FetchDescriptor<NutritionCacheEntry>()
            let allEntries = try modelContext.fetch(descriptor)
            
            let expiredCount = allEntries.filter { $0.isExpired }.count
            
            // Estimate cache size (very rough approximation)
            let estimatedSizeMB = Double(allEntries.count * 200) / (1024 * 1024) // ~200 bytes per entry
            
            return (total: allEntries.count, expired: expiredCount, totalSizeMB: estimatedSizeMB)
        } catch {
            print("❌ [NutritionCache] Failed to get cache stats: \(error)")
            return (total: 0, expired: 0, totalSizeMB: 0.0)
        }
    }
    
    /// Schedule automatic cleanup every hour
    private func scheduleAutomaticCleanup() async {
        // Check if we should run cleanup
        let lastCleanupKey = "lastNutritionCacheCleanup"
        let lastCleanup = UserDefaults.standard.object(forKey: lastCleanupKey) as? Date ?? Date.distantPast
        let hoursSinceLastCleanup = Date().timeIntervalSince(lastCleanup) / 3600
        
        if hoursSinceLastCleanup >= 1.0 {
            await cleanupExpiredEntries()
            UserDefaults.standard.set(Date(), forKey: lastCleanupKey)
        }
        
        // Set up notification for app becoming active
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.cleanupExpiredEntries()
            }
        }
    }
    
    /// Clear all cached nutrition data (for testing/reset)
    func clearAllCache() async {
        do {
            let descriptor = FetchDescriptor<NutritionCacheEntry>()
            let allEntries = try modelContext.fetch(descriptor)
            
            for entry in allEntries {
                modelContext.delete(entry)
            }
            
            try modelContext.save()
            print("🗑️ [NutritionCache] Cleared all cached nutrition data")
            
        } catch {
            print("❌ [NutritionCache] Failed to clear cache: \(error)")
        }
    }
} 
