// MacroEntryStore.swift
// SwiftData service layer for MacroEntry operations
import Foundation
import SwiftData
import SwiftUI
import UIKit
internal import Combine

final class MacroEntryStore: ObservableObject {
    var modelContext: ModelContext
    
    // Serial queue to prevent concurrent SwiftData operations
    private let saveQueue = DispatchQueue(label: "com.macroai.swiftdata.save", qos: .userInitiated)
    private var isSaving = false
    
    // Published properties for UI binding
    @Published var entries: [MacroEntry] = []
    @Published var isLoading = false
    @Published var error: MacroEntryError?
    
    // Today's total macros (computed from entries)
    var todaysTotals: (calories: Int, protein: Int, carbs: Int, fats: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todaysEntries = entries.filter { entry in
            entry.timestamp >= today && entry.timestamp < tomorrow
        }
        
        return todaysEntries.reduce((0, 0, 0, 0)) { totals, entry in
            (
                totals.0 + entry.calories,
                totals.1 + entry.protein,
                totals.2 + entry.carbs,
                totals.3 + entry.fats
            )
        }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Initialize with empty state, fetch will be called explicitly
        
        // Set up daily refresh notification
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.refreshEntriesIfNeeded()
            }
        }
    }
    
    // MARK: - Core Operations
    
    /// Fetch all entries from the database
    @MainActor
    func fetchEntries() async {
        isLoading = true
        error = nil
        
        do {
            let descriptor = FetchDescriptor<MacroEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            entries = try modelContext.fetch(descriptor)
            print("✅ [MacroEntryStore] Fetched \(entries.count) entries")
        } catch {
            print("❌ [MacroEntryStore] Failed to fetch entries: \(error)")
            self.error = .fetchFailed(error)
            entries = []
        }
        
        isLoading = false
    }
    
    /// Add a new macro entry
    func addEntry(
        foodName: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fats: Int,
        imageData: Data? = nil
    ) async -> MacroEntry? {
        
        let entry = MacroEntry(
            name: foodName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats,
            imageData: imageData
        )
        
        return await addEntry(entry)
    }
    
    /// Add a new macro entry with serving size data
    func addEntry(
        foodName: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fats: Int,
        servingSize: Double,
        servingSizeType: ServingSizeType,
        baseServingSize: Double,
        baseServingSizeType: ServingSizeType,
        imageData: Data? = nil
    ) async -> MacroEntry? {
        
        let entry = MacroEntry(
            name: foodName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats,
            imageData: imageData,
            servingSize: servingSize,
            servingSizeType: servingSizeType,
            baseServingSize: baseServingSize,
            baseServingSizeType: baseServingSizeType
        )
        
        return await addEntry(entry)
    }
    
    /// Add an existing MacroEntry object with improved error handling
    @MainActor
    func addEntry(_ entry: MacroEntry) async -> MacroEntry? {
        // Prevent concurrent saves
        guard !isSaving else {
            print("⚠️ [MacroEntryStore] Save operation already in progress, skipping")
            return nil
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Validate entry data before saving
            guard !entry.foodName.isEmpty else {
                throw MacroEntryError.invalidData("Food name cannot be empty")
            }
            
            // Limit image size to prevent BackingData encoding issues
            if let imageData = entry.imageData {
                print("📸 [MacroEntryStore] Saving entry with image data: \(imageData.count) bytes")
                if imageData.count > 5_000_000 { // 5MB limit
                    print("⚠️ [MacroEntryStore] Image too large (\(imageData.count) bytes), compressing...")
                    entry.imageData = compressImageData(imageData)
                }
            } else {
                print("📸 [MacroEntryStore] Saving entry without image data")
            }
            
            modelContext.insert(entry)
            
            // Use a retry mechanism for save operations
            var retryCount = 0
            let maxRetries = 3
            
            while retryCount < maxRetries {
                do {
                    try modelContext.save()
                    break // Success, exit retry loop
                } catch {
                    retryCount += 1
                    print("❌ [MacroEntryStore] Save attempt \(retryCount) failed: \(error)")
                    
                    if retryCount >= maxRetries {
                        throw error
                    }
                    
                    // Wait before retrying
                    try await Task.sleep(for: .milliseconds(100 * retryCount))
                }
            }
            
            // Update local array and notify observers
            objectWillChange.send()
            entries.insert(entry, at: 0) // Add to beginning (most recent first)
            
            print("✅ [MacroEntryStore] Added entry: \(entry.foodName) - \(entry.calories) cal")
            print("📊 [MacroEntryStore] Updated today's totals: \(todaysTotals)")
            
            // Sync to HealthKit (now free for all users)
            await HealthKitManager.shared.writeMealToHealthKit(entry)
            
            return entry
            
        } catch {
            print("❌ [MacroEntryStore] Failed to add entry: \(error)")
            
            // Handle specific SwiftData errors
            if error.localizedDescription.contains("BackingData") {
                self.error = .saveFailed(NSError(domain: "SwiftDataError", code: 1001, userInfo: [
                    NSLocalizedDescriptionKey: "Database save failed. Please try again or restart the app."
                ]))
            } else {
                self.error = .saveFailed(error)
            }
            return nil
        }
    }
    
    /// Delete a macro entry with improved error handling
    @MainActor
    func deleteEntry(_ entry: MacroEntry) async {
        guard !isSaving else {
            print("⚠️ [MacroEntryStore] Save operation in progress, cannot delete")
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            modelContext.delete(entry)
            
            // Use retry mechanism for delete operations too
            var retryCount = 0
            let maxRetries = 3
            
            while retryCount < maxRetries {
                do {
                    try modelContext.save()
                    break
                } catch {
                    retryCount += 1
                    print("❌ [MacroEntryStore] Delete attempt \(retryCount) failed: \(error)")
                    
                    if retryCount >= maxRetries {
                        throw error
                    }
                    
                    try await Task.sleep(for: .milliseconds(100 * retryCount))
                }
            }
            
            // Update local array
            entries.removeAll { $0.id == entry.id }
            
            print("✅ [MacroEntryStore] Deleted entry: \(entry.foodName)")
            
        } catch {
            print("❌ [MacroEntryStore] Failed to delete entry: \(error)")
            if error.localizedDescription.contains("BackingData") {
                self.error = .deleteFailed(NSError(domain: "SwiftDataError", code: 1002, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to delete entry. Please try again or restart the app."
                ]))
            } else {
                self.error = .deleteFailed(error)
            }
        }
    }
    
    /// Update an existing entry with improved error handling
    @MainActor
    func updateEntry(_ entry: MacroEntry) async {
        guard !isSaving else {
            print("⚠️ [MacroEntryStore] Save operation in progress, cannot update")
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Validate and compress image if needed
            if let imageData = entry.imageData, imageData.count > 5_000_000 {
                entry.imageData = compressImageData(imageData)
            }
            
            var retryCount = 0
            let maxRetries = 3
            
            while retryCount < maxRetries {
                do {
                    try modelContext.save()
                    break
                } catch {
                    retryCount += 1
                    print("❌ [MacroEntryStore] Update attempt \(retryCount) failed: \(error)")
                    
                    if retryCount >= maxRetries {
                        throw error
                    }
                    
                    try await Task.sleep(for: .milliseconds(100 * retryCount))
                }
            }
            
            // Refresh the local array
            await fetchEntries()
            
            print("✅ [MacroEntryStore] Updated entry: \(entry.foodName)")
            
        } catch {
            print("❌ [MacroEntryStore] Failed to update entry: \(error)")
            if error.localizedDescription.contains("BackingData") {
                self.error = .updateFailed(NSError(domain: "SwiftDataError", code: 1003, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to update entry. Please try again or restart the app."
                ]))
            } else {
                self.error = .updateFailed(error)
            }
        }
    }
    
    // MARK: - Query Operations
    
    /// Get entries for a specific date
    func entriesForDate(_ date: Date) -> [MacroEntry] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return entries.filter { entry in
            entry.timestamp >= startOfDay && entry.timestamp < endOfDay
        }
    }
    
    /// Get entries for today
    var todaysEntries: [MacroEntry] {
        entriesForDate(Date())
    }
    
    /// Get entries that have photos
    var entriesWithPhotos: [MacroEntry] {
        entries.filter { $0.imageData != nil }
    }
    
    /// Get the most recent entry
    var latestEntry: MacroEntry? {
        entries.first
    }
    
    /// Get total number of entries
    var totalEntryCount: Int {
        entries.count
    }
    
    /// Get total number of photos
    var totalPhotoCount: Int {
        entriesWithPhotos.count
    }
    
    /// Estimate total photo storage size in MB
    var estimatedPhotoStorageMB: Double {
        let totalBytes = entriesWithPhotos.reduce(0) { total, entry in
            total + (entry.imageData?.count ?? 0)
        }
        return Double(totalBytes) / (1024 * 1024) // Convert to MB
    }
    
    // MARK: - Photo Management
    
    /// Clean up photos older than specified days to keep app lightweight
    @MainActor
    func cleanupOldPhotos(olderThanDays: Int = 7) async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date())!
        
        let oldEntries = entries.filter { entry in
            entry.timestamp < cutoffDate && entry.imageData != nil
        }
        
        guard !oldEntries.isEmpty else {
            print("✅ [MacroEntryStore] No old photos to clean up")
            return
        }
        
        var cleanedCount = 0
        var spaceSavedMB: Double = 0
        
        for entry in oldEntries {
            if let imageData = entry.imageData {
                spaceSavedMB += Double(imageData.count) / (1024 * 1024)
                entry.imageData = nil // Remove photo but keep entry
                cleanedCount += 1
            }
        }
        
        do {
            try modelContext.save()
            print("✅ [MacroEntryStore] Cleaned up \(cleanedCount) photos, saved \(String(format: "%.1f", spaceSavedMB)) MB")
        } catch {
            print("❌ [MacroEntryStore] Failed to save after photo cleanup: \(error)")
            self.error = .updateFailed(error)
        }
    }
    
    /// Setup automatic daily photo cleanup
    func scheduleAutomaticPhotoCleanup() {
        // Check if we should run cleanup (once per day)
        let lastCleanupKey = "lastPhotoCleanupDate"
        let lastCleanup = UserDefaults.standard.object(forKey: lastCleanupKey) as? Date ?? Date.distantPast
        let daysSinceLastCleanup = Calendar.current.dateComponents([.day], from: lastCleanup, to: Date()).day ?? 0
        
        if daysSinceLastCleanup >= 1 {
            Task {
                await cleanupOldPhotos(olderThanDays: 7) // Keep photos for 7 days
                UserDefaults.standard.set(Date(), forKey: lastCleanupKey)
            }
        }
    }
    
    // MARK: - Daily Refresh
    
    /// Refresh entries if we've crossed to a new day
    @MainActor
    private func refreshEntriesIfNeeded() async {
        let lastRefreshKey = "lastMacroEntryRefresh"
        let lastRefresh = UserDefaults.standard.object(forKey: lastRefreshKey) as? Date ?? Date.distantPast
        
        // Check if it's been more than 12 hours or if we're on a new day
        if !Calendar.current.isDate(lastRefresh, inSameDayAs: Date()) ||
           Date().timeIntervalSince(lastRefresh) > 12 * 60 * 60 {
            
            print("🔄 [MacroEntryStore] Refreshing entries for new day/session")
            await fetchEntries()
            UserDefaults.standard.set(Date(), forKey: lastRefreshKey)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Compress image data to prevent BackingData encoding issues
    private func compressImageData(_ imageData: Data) -> Data? {
        guard let image = UIImage(data: imageData) else { return imageData }
        
        // Start with high quality and reduce until under 5MB
        var quality: CGFloat = 0.8
        var compressedData = image.jpegData(compressionQuality: quality)
        
        while let data = compressedData, data.count > 5_000_000 && quality > 0.1 {
            quality -= 0.1
            compressedData = image.jpegData(compressionQuality: quality)
        }
        
        let finalSize = compressedData?.count ?? 0
        print("🗜️ [MacroEntryStore] Compressed image from \(imageData.count) to \(finalSize) bytes")
        
        return compressedData ?? imageData
    }
    
    // MARK: - Utility Operations
    
    /// Clear error state
    func clearError() {
        error = nil
    }
    
    /// Delete all entries (for testing/reset purposes)
    @MainActor
    func deleteAllEntries() async {
        do {
            let descriptor = FetchDescriptor<MacroEntry>()
            let allEntries = try modelContext.fetch(descriptor)
            
            for entry in allEntries {
                modelContext.delete(entry)
            }
            
            try modelContext.save()
            entries.removeAll()
            
            print("✅ [MacroEntryStore] Deleted all entries")
            
        } catch {
            print("❌ [MacroEntryStore] Failed to delete all entries: \(error)")
            self.error = .deleteFailed(error)
        }
    }
    
    /// Add sample data for testing
    @MainActor
    func addSampleData() async {
        for sampleEntry in MacroEntry.sampleEntries {
            _ = await addEntry(sampleEntry)
        }
    }
    
    /// Test image storage functionality
    @MainActor
    func testImageStorage() async {
        print("🧪 [MacroEntryStore] Testing image storage...")
        
        // Create a simple test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = testImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ [MacroEntryStore] Failed to create test image")
            return
        }
        
        print("🧪 [MacroEntryStore] Created test image: \(imageData.count) bytes")
        
        // Create test entry with image
        let testEntry = MacroEntry(
            name: "Test Image Entry",
            calories: 100,
            protein: 10,
            carbs: 10,
            fats: 5,
            imageData: imageData,
            source: .manual
        )
        
        // Save the entry
        if let savedEntry = await addEntry(testEntry) {
            print("✅ [MacroEntryStore] Test entry saved successfully")
            
            // Verify the image data is still there
            if let savedImageData = savedEntry.imageData {
                print("✅ [MacroEntryStore] Image data preserved: \(savedImageData.count) bytes")
                
                // Try to create UIImage from saved data
                if UIImage(data: savedImageData) != nil {
                    print("✅ [MacroEntryStore] Successfully recreated UIImage from saved data")
                } else {
                    print("❌ [MacroEntryStore] Failed to recreate UIImage from saved data")
                }
            } else {
                print("❌ [MacroEntryStore] Image data missing from saved entry")
            }
        } else {
            print("❌ [MacroEntryStore] Failed to save test entry")
        }
    }
}

// MARK: - Error Handling

enum MacroEntryError: LocalizedError {
    case fetchFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    case updateFailed(Error)
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to load entries: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save entry: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete entry: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update entry: \(error.localizedDescription)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
} 

