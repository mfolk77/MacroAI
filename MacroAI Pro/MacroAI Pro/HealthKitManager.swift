// HealthKitManager.swift
// Manages HealthKit integration for premium users
import Foundation
import HealthKit
import SwiftUI
internal import Combine

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isHealthKitAvailable: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var authorizationError: String?
    
    private let healthStore = HKHealthStore()
    
    // HealthKit data types we want to read/write
    private let nutritionTypes: Set<HKSampleType> = [
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryFatTotal),
        HKQuantityType(.dietaryFiber),
        HKQuantityType(.dietarySugar),
        HKQuantityType(.dietarySodium)
    ]
    
    // Additional health metrics to read
    private let healthMetrics: Set<HKSampleType> = [
        HKQuantityType(.bodyMass),
        HKQuantityType(.height),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.basalEnergyBurned)
    ]
    
    init() {
        checkHealthKitAvailability()
    }
    
    // MARK: - Availability Check
    
    private func checkHealthKitAvailability() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
        print("ℹ️ [HealthKitManager] HealthKit available: \(isHealthKitAvailable)")
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            authorizationError = "HealthKit is not available on this device"
            return
        }
        
        // HealthKit is now free for all users
        
        let allTypes = nutritionTypes.union(healthMetrics)
        
        do {
            try await healthStore.requestAuthorization(toShare: nutritionTypes, read: allTypes)
            await checkAuthorizationStatus()
            print("✅ [HealthKitManager] Authorization requested successfully")
        } catch {
            authorizationError = "Failed to request HealthKit authorization: \(error.localizedDescription)"
            print("❌ [HealthKitManager] Authorization failed: \(error)")
        }
    }
    
    private func checkAuthorizationStatus() async {
        let readStatuses = healthMetrics.union(nutritionTypes).map { type in
            healthStore.authorizationStatus(for: type)
        }
        
        let writeStatuses = nutritionTypes.map { type in
            healthStore.authorizationStatus(for: type)
        }
        
        // HealthKit write permissions are often "not determined" but still work
        let hasReadAccess = readStatuses.contains { $0 == .sharingAuthorized }
        let hasWriteAccess = writeStatuses.allSatisfy { $0 != .sharingDenied }
        
        isAuthorized = hasWriteAccess // Focus on write access since that's what we need
        print("ℹ️ [HealthKitManager] Authorization status - Read: \(hasReadAccess), Write: \(hasWriteAccess)")
        print("🔍 [HealthKitManager] Setting isAuthorized to: \(isAuthorized)")
    }
    
    // MARK: - Writing Data to HealthKit
    
    func writeMealToHealthKit(_ entry: MacroEntry) async {
        guard isAuthorized else {
            print("⚠️ [HealthKitManager] Cannot write - not authorized")
            return
        }
        
        var samples: [HKQuantitySample] = []
        let now = Date()
        
        // Create samples for each macro
        if let caloriesSample = createQuantitySample(
            type: HKQuantityType(.dietaryEnergyConsumed),
            value: Double(entry.calories),
            unit: .kilocalorie(),
            date: now
        ) {
            samples.append(caloriesSample)
        }
        
        if let proteinSample = createQuantitySample(
            type: HKQuantityType(.dietaryProtein),
            value: Double(entry.protein),
            unit: .gram(),
            date: now
        ) {
            samples.append(proteinSample)
        }
        
        if let carbsSample = createQuantitySample(
            type: HKQuantityType(.dietaryCarbohydrates),
            value: Double(entry.carbs),
            unit: .gram(),
            date: now
        ) {
            samples.append(carbsSample)
        }
        
        if let fatsSample = createQuantitySample(
            type: HKQuantityType(.dietaryFatTotal),
            value: Double(entry.fats),
            unit: .gram(),
            date: now
        ) {
            samples.append(fatsSample)
        }
        
        // Save all samples
        do {
            try await healthStore.save(samples)
            print("✅ [HealthKitManager] Saved \(samples.count) nutrition samples to HealthKit")
        } catch {
            print("❌ [HealthKitManager] Failed to save to HealthKit: \(error)")
        }
    }
    
    private func createQuantitySample(
        type: HKQuantityType,
        value: Double,
        unit: HKUnit,
        date: Date
    ) -> HKQuantitySample? {
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        
        return HKQuantitySample(
            type: type,
            quantity: quantity,
            start: date,
            end: date,
            metadata: [
                HKMetadataKeyWasUserEntered: true,
                "MacroAI": "Generated by MacroAI app"
            ]
        )
    }
    
    // MARK: - Reading Data from HealthKit
    
    func getTodaysNutritionData() async -> NutritionSummary? {
        guard isAuthorized else {
            print("⚠️ [HealthKitManager] Cannot read - not authorized")
            return nil
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        do {
            let calories = try await queryNutritionData(type: .dietaryEnergyConsumed, predicate: predicate)
            let protein = try await queryNutritionData(type: .dietaryProtein, predicate: predicate)
            let carbs = try await queryNutritionData(type: .dietaryCarbohydrates, predicate: predicate)
            let fats = try await queryNutritionData(type: .dietaryFatTotal, predicate: predicate)
            
            return NutritionSummary(
                calories: Int(calories),
                protein: Int(protein),
                carbs: Int(carbs),
                fats: Int(fats),
                lastUpdated: now
            )
        } catch {
            print("❌ [HealthKitManager] Failed to read nutrition data: \(error)")
            return nil
        }
    }
    
    private func queryNutritionData(
        type: HKQuantityTypeIdentifier,
        predicate: NSPredicate
    ) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: HKQuantityType(type),
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let sum = result?.sumQuantity() ?? HKQuantity(unit: self.getUnit(for: type), doubleValue: 0)
                let value = sum.doubleValue(for: self.getUnit(for: type))
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
    
    nonisolated private func getUnit(for type: HKQuantityTypeIdentifier) -> HKUnit {
        switch type {
        case .dietaryEnergyConsumed:
            return .kilocalorie()
        case .dietaryProtein, .dietaryCarbohydrates, .dietaryFatTotal:
            return .gram()
        default:
            return .gram()
        }
    }
    
    // MARK: - User Health Metrics
    
    func getUserMetrics() async -> UserMetrics? {
        guard isAuthorized else { return nil }
        
        do {
            let weight = try await getLatestQuantityValue(for: .bodyMass, unit: .pound())
            let height = try await getLatestQuantityValue(for: .height, unit: .inch())
            
            return UserMetrics(
                weight: weight,
                height: height,
                lastUpdated: Date()
            )
        } catch {
            print("❌ [HealthKitManager] Failed to get user metrics: \(error)")
            return nil
        }
    }
    
    private func getLatestQuantityValue(
        for type: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async throws -> Double? {
        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: HKQuantityType(type),
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - Data Structures

struct NutritionSummary {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fats: Int
    let lastUpdated: Date
}

struct UserMetrics {
    let weight: Double?
    let height: Double?
    let lastUpdated: Date
}

// MARK: - Extensions

extension HealthKitManager {
    var isPremiumRequired: Bool {
        false  // HealthKit is now free for all users
    }
    
    var statusMessage: String {
        if !isHealthKitAvailable {
            return "HealthKit is not available on this device"
        } else if !isAuthorized {
            return "Please authorize HealthKit access in Settings"
        } else {
            return "HealthKit integration is active"
        }
    }
} 