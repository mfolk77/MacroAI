// NutritionCacheCleanupTask.swift
// Background task for cleaning up expired nutrition cache entries (Spoonacular compliance)
import Foundation
import BackgroundTasks
import SwiftData

class NutritionCacheCleanupTask {
    static let shared = NutritionCacheCleanupTask()
    
    private let taskIdentifier = "com.macroai.nutritionCleanup"
    private var modelContainer: ModelContainer?
    
    private init() {}
    
    /// Register the background task with the system
    /// Note: Disabled due to Info.plist configuration requirements
    func registerBackgroundTask() {
        // Background task registration requires Info.plist configuration
        // For now, cleanup happens during app launch and manually
        print("🧹 [NutritionCleanupTask] Background task registration disabled - using manual cleanup")
    }
    
    /// Set the model container for database access
    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
    }
    
    /// Schedule the next background cleanup
    /// Note: Disabled - cleanup happens manually
    func scheduleNextCleanup() {
        // Background scheduling disabled - cleanup happens during app launch
        print("🧹 [NutritionCleanupTask] Background scheduling disabled - cleanup happens manually")
    }
    
    /// Handle the background cleanup task
    private func handleBackgroundCleanup(task: BGProcessingTask) async {
        task.expirationHandler = {
            print("⏰ [NutritionCleanupTask] Task expired")
            task.setTaskCompleted(success: false)
        }
        
        let deletedCount = await cleanupExpiredEntries()
        print("🧹 [NutritionCleanupTask] Cleaned up \(deletedCount) expired nutrition cache entries")
        task.setTaskCompleted(success: true)
        
        // Schedule the next cleanup
        scheduleNextCleanup()
    }
    
    /// Clean up expired nutrition cache entries
    @MainActor
    func cleanupExpiredEntries() async -> Int {
        guard let container = modelContainer else {
            print("❌ [NutritionCleanupTask] No model container available")
            return 0
        }
        
        let context = container.mainContext
        var deletedCount = 0
        
        do {
            // Fetch all nutrition cache entries
            let descriptor = FetchDescriptor<NutritionCacheEntry>()
            let allEntries = try context.fetch(descriptor)
            
            // Filter expired entries (older than 1 hour)
            let expiredEntries = allEntries.filter { $0.isExpired }
            
            // Delete expired entries
            for entry in expiredEntries {
                context.delete(entry)
                deletedCount += 1
            }
            
            if deletedCount > 0 {
                try context.save()
                print("🧹 [NutritionCleanupTask] Deleted \(deletedCount) expired entries (Spoonacular compliance)")
            }
            
        } catch {
            print("❌ [NutritionCleanupTask] Failed to cleanup expired entries: \(error)")
        }
        
        return deletedCount
    }
    
    /// Perform immediate cleanup (can be called manually)
    func performImmediateCleanup() async -> Int {
        return await cleanupExpiredEntries()
    }
} 