//  AutoTuneEngine.swift
//  MacroAI
//
//  MVP rule-based weekly auto-tune for macro targets.
//  Persists weekly records via UserDefaults JSON (no SwiftData schema changes).

import Foundation
import SwiftData
import HealthKit
import UserNotifications
import UIKit

// MARK: - AutoTune Record (persisted via UserDefaults)

struct AutoTuneRecord: Codable, Identifiable {
    let id: UUID
    let weekStart: Date
    let weekEnd: Date
    let avgCalories: Double
    let avgProtein: Double
    let weightDeltaKg: Double?
    let activityScore: Double
    let adjustmentApplied: Double // percentage change applied to calories, e.g., -0.07
    let newTargets: MacroTargetsSnapshot
    let createdAt: Date
    let notes: String?
    
    struct MacroTargetsSnapshot: Codable {
        let protein: Double
        let fats: Double
        let carbs: Double
        let estimatedCalories: Int
    }
}

// MARK: - Engine

@MainActor
final class AutoTuneEngine {
    static let shared = AutoTuneEngine()
    
    private let defaults = UserDefaults.standard
    private let recordsKey = "autotune_records_v1"
    private let lastRunKey = "autotune_last_run_v1"
    private let featureFlagKey = "autoTuneEnabled"
    private let bannerDismissUntilKey = "autotune_banner_dismiss_until_v1"
    
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    // MARK: - Public API
    
    func runWeeklyAdjustmentIfDue(modelContext: ModelContext) async {
        guard isFeatureEnabled() else { return }
        guard isUserEligibleForAutoTune() else { return }
        
        let now = Date()
        if let lastRun = defaults.object(forKey: lastRunKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: lastRun, to: now).day ?? 0
            if days < 7 { return }
        }
        
        #if DEBUG
        print("🔧 [AutoTune] Starting weekly adjustment run...")
        #endif
        
        // Signals window: last 7 days
        guard let windowStart = Calendar.current.date(byAdding: .day, value: -7, to: now) else { return }
        let windowEnd = now
        
        // Fetch signals concurrently
        let caloriesTask = Task { await self.getSevenDayAverageCalories(modelContext: modelContext, start: windowStart, end: windowEnd) }
        let proteinTask = Task { await self.getSevenDayAverageProtein(modelContext: modelContext, start: windowStart, end: windowEnd) }
        let weightDeltaTask = Task { await self.getSevenDayWeightDeltaKg(start: windowStart, end: windowEnd) }
        let activityTask = Task { await self.getActivityScore(start: windowStart, end: windowEnd) }
        
        let avgCalories = await caloriesTask.value
        let avgProtein = await proteinTask.value
        let weightDeltaKg = await weightDeltaTask.value
        let activityScore = await activityTask.value
        
        // If no weight samples at all, skip applying adjustments per spec
        guard weightDeltaKg != nil else {
            #if DEBUG
            print("ℹ️ [AutoTune] Skipping adjustment: no recent weight data.")
            #endif
            defaults.set(now, forKey: lastRunKey)
            await sendNotification(title: "Auto‑Tune Skipped", body: "No weight data found in the last 7 days.")
            return
        }
        
        let currentTargets = MacroTargets.current
        let currentEstimatedCalories = max(1200, min(5000, currentTargets.estimatedCalories))
        
        // Decide goal: default to weight loss; allow maintenance via stored flag if present
        let goalString = defaults.string(forKey: "diet_goal") ?? "weightLoss"
        let goal: Goal = (goalString == "maintenance") ? .maintenance : .weightLoss
        
        // Compute rule-based adjustment
        let adjustment = computeWeeklyAdjustment(
            goal: goal,
            weightDeltaKg: weightDeltaKg ?? 0,
            avgCalories: avgCalories,
            targetCalories: Double(currentEstimatedCalories)
        )
        
        // Apply ±10% weekly clamp
        let clampedChange = max(-0.10, min(0.10, adjustment))
        let newCalories = max(1000.0, Double(currentEstimatedCalories) * (1.0 + clampedChange))
        
        // Recompute macro targets given new calories, preserve protein grams
        let newTargets = recomputeMacros(
            newCalories: newCalories,
            preserveProteinGrams: currentTargets.protein,
            windowStart: windowStart,
            windowEnd: windowEnd
        )
        newTargets.save()
        
        #if DEBUG
        print("✅ [AutoTune] Applied change: \(Int(clampedChange * 100))% → new est kcal=\(Int(newCalories)) → P=\(Int(newTargets.protein)) F=\(Int(newTargets.fats)) C=\(Int(newTargets.carbs))")
        #endif
        
        // Persist record
        let record = AutoTuneRecord(
            id: UUID(),
            weekStart: windowStart,
            weekEnd: windowEnd,
            avgCalories: avgCalories,
            avgProtein: avgProtein,
            weightDeltaKg: weightDeltaKg,
            activityScore: activityScore,
            adjustmentApplied: clampedChange,
            newTargets: .init(
                protein: newTargets.protein,
                fats: newTargets.fats,
                carbs: newTargets.carbs,
                estimatedCalories: newTargets.estimatedCalories
            ),
            createdAt: now,
            notes: nil
        )
        saveRecord(record)
        
        // Mark last run
        defaults.set(now, forKey: lastRunKey)
        
        // Haptic + notification
        triggerSuccessHaptic()
        await sendNotification(
            title: "Auto‑Tune Updated",
            body: "Your daily target changed \(Int(clampedChange * 100))% to \(Int(newCalories)) kcal."
        )
    }
    
    // MARK: - Simulation (no HealthKit needed)
    
    func simulateWithMockData(modelContext: ModelContext) async {
        #if DEBUG
        let now = Date()
        guard let windowStart = Calendar.current.date(byAdding: .day, value: -7, to: now) else { return }
        let windowEnd = now
        let avgCalories = await getSevenDayAverageCalories(modelContext: modelContext, start: windowStart, end: windowEnd)
        let avgProtein = await getSevenDayAverageProtein(modelContext: modelContext, start: windowStart, end: windowEnd)
        let currentTargets = MacroTargets.current
        let currentEstimatedCalories = max(1200, min(5000, currentTargets.estimatedCalories))
        let goal: Goal = .weightLoss
        let adjustment = computeWeeklyAdjustment(goal: goal, weightDeltaKg: 0.25, avgCalories: avgCalories, targetCalories: Double(currentEstimatedCalories))
        let clampedChange = max(-0.10, min(0.10, adjustment))
        let newCalories = max(1000.0, Double(currentEstimatedCalories) * (1.0 + clampedChange))
        let newTargets = recomputeMacros(newCalories: newCalories, preserveProteinGrams: currentTargets.protein, windowStart: windowStart, windowEnd: windowEnd)
        newTargets.save()
        print("🧪 [AutoTune] Simulation applied change: \(Int(clampedChange * 100))% → new est kcal=\(Int(newCalories))")
        #endif
    }
    
    // MARK: - DEBUG Seeding
    /// Creates a recent Auto‑Tune record in DEBUG builds if none exists yet, to surface the banner for testing.
    func seedDebugRecordIfMissing(modelContext: ModelContext) async {
        #if DEBUG
        if lastRecord() != nil { return }
        let now = Date()
        guard let windowStart = Calendar.current.date(byAdding: .day, value: -7, to: now) else { return }
        let windowEnd = now
        let avgCalories = await getSevenDayAverageCalories(modelContext: modelContext, start: windowStart, end: windowEnd)
        let avgProtein = await getSevenDayAverageProtein(modelContext: modelContext, start: windowStart, end: windowEnd)
        let currentTargets = MacroTargets.current
        let currentEstimatedCalories = max(1200, min(5000, currentTargets.estimatedCalories))
        let clampedChange = 0.04 // +4% demo adjustment
        let newCalories = max(1000.0, Double(currentEstimatedCalories) * (1.0 + clampedChange))
        let newTargets = recomputeMacros(newCalories: newCalories, preserveProteinGrams: currentTargets.protein, windowStart: windowStart, windowEnd: windowEnd)
        let record = AutoTuneRecord(
            id: UUID(),
            weekStart: windowStart,
            weekEnd: windowEnd,
            avgCalories: avgCalories,
            avgProtein: avgProtein,
            weightDeltaKg: 0.2,
            activityScore: 0.7,
            adjustmentApplied: clampedChange,
            newTargets: .init(
                protein: newTargets.protein,
                fats: newTargets.fats,
                carbs: newTargets.carbs,
                estimatedCalories: newTargets.estimatedCalories
            ),
            createdAt: now,
            notes: "DEBUG_SEED"
        )
        saveRecord(record)
        #endif
    }
    
    // MARK: - Signals
    
    private func getSevenDayAverageCalories(modelContext: ModelContext, start: Date, end: Date) async -> Double {
        let descriptor = FetchDescriptor<MacroEntry>(
            predicate: #Predicate { entry in
                entry.timestamp >= start && entry.timestamp < end
            },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        do {
            let entries = try modelContext.fetch(descriptor)
            // Group by day and sum calories per day
            let calendar = Calendar.current
            var dayTotals: [Date: Int] = [:]
            for e in entries {
                let day = calendar.startOfDay(for: e.timestamp)
                dayTotals[day, default: 0] += e.calories
            }
            let dailyValues = dayTotals.values.map { Double($0) }
            if dailyValues.isEmpty { return 0 }
            return dailyValues.reduce(0, +) / Double(dailyValues.count)
        } catch {
            #if DEBUG
            print("❌ [AutoTune] Failed to fetch entries for calories: \(error)")
            #endif
            return 0
        }
    }
    
    private func getSevenDayAverageProtein(modelContext: ModelContext, start: Date, end: Date) async -> Double {
        let descriptor = FetchDescriptor<MacroEntry>(
            predicate: #Predicate { entry in
                entry.timestamp >= start && entry.timestamp < end
            },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        do {
            let entries = try modelContext.fetch(descriptor)
            // Group by day and sum protein per day
            let calendar = Calendar.current
            var dayTotals: [Date: Int] = [:]
            for e in entries {
                let day = calendar.startOfDay(for: e.timestamp)
                dayTotals[day, default: 0] += e.protein
            }
            let dailyValues = dayTotals.values.map { Double($0) }
            if dailyValues.isEmpty { return 0 }
            return dailyValues.reduce(0, +) / Double(dailyValues.count)
        } catch {
            #if DEBUG
            print("❌ [AutoTune] Failed to fetch entries for protein: \(error)")
            #endif
            return 0
        }
    }
    
    private func getSevenDayWeightDeltaKg(start: Date, end: Date) async -> Double? {
        // Respect existing authorization state
        if !HealthKitManager.shared.isAuthorized { return nil }
        
        let type = HKQuantityType(.bodyMass)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { [weak self] _, samples, error in
                guard error == nil, let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                // Compute delta between first and last in kg
                let unit = HKUnit.gramUnit(with: .kilo)
                let first = samples.first!.quantity.doubleValue(for: unit)
                let last = samples.last!.quantity.doubleValue(for: unit)
                let delta = last - first
                #if DEBUG
                _ = self // silence unused warning; self not used intentionally
                #endif
                continuation.resume(returning: delta)
            }
            healthStore.execute(query)
        }
    }
    
    private func getActivityScore(start: Date, end: Date) async -> Double {
        // Respect existing authorization; fallback 0
        if !HealthKitManager.shared.isAuthorized { return 0 }
        
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        // Sum steps over window
        let steps: Double = await withCheckedContinuation { (continuation: CheckedContinuation<Double, Never>) in
            let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if error != nil { continuation.resume(returning: 0); return }
                let unit = HKUnit.count()
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
        
        // Normalize roughly: 10k daily ~ 70k weekly ≈ score 1.0
        let scoreFromSteps = min(1.5, steps / 70000.0)
        return max(0, scoreFromSteps)
    }
    
    // MARK: - Logic
    
    private enum Goal { case weightLoss, maintenance }
    
    private func computeWeeklyAdjustment(goal: Goal, weightDeltaKg: Double, avgCalories: Double, targetCalories: Double) -> Double {
        switch goal {
        case .weightLoss:
            // If weight increased more than +0.2 kg/week and eating > target+8% → lower calories −7%
            if weightDeltaKg > 0.2 && avgCalories > targetCalories * 1.08 {
                return -0.07
            }
            // If losing too fast (< -0.5 kg/week) or avgCalories < target−12% → raise calories +5%
            if weightDeltaKg < -0.5 || avgCalories < targetCalories * 0.88 {
                return 0.05
            }
            // Otherwise small nudge back toward target if drifted
            if avgCalories > targetCalories * 1.05 { return -0.03 }
            if avgCalories < targetCalories * 0.95 { return 0.03 }
            return 0
        case .maintenance:
            // Keep within ±5%; otherwise nudge back
            if avgCalories > targetCalories * 1.05 { return -0.03 }
            if avgCalories < targetCalories * 0.95 { return 0.03 }
            return 0
        }
    }
    
    private func recomputeMacros(newCalories: Double, preserveProteinGrams: Double, windowStart: Date, windowEnd: Date) -> MacroTargets {
        // Try to use active DietPack fat percent bounds; fallback to 20–35%
        let activeDietId = DietManager.shared.currentDiet.id
        let packs = MarketplaceManager.shared.dietPacks
        let fatPercentRange: ClosedRange<Int>
        if let pack = packs.first(where: { $0.id == activeDietId }) {
            fatPercentRange = pack.macroRanges.fat
        } else {
            fatPercentRange = 20...35
        }
        
        // Preserve protein grams; ensure it's within reasonable bounds
        let proteinGrams = max(50, min(300, preserveProteinGrams))
        let proteinKcal = proteinGrams * 4.0
        
        // Choose fat percent mid-point within bounds
        let fatPercent = Double(fatPercentRange.lowerBound + fatPercentRange.upperBound) / 2.0 / 100.0
        var fatKcal = newCalories * fatPercent
        var fatGrams = fatKcal / 9.0
        
        // Remainder for carbs
        var remainingKcal = max(0, newCalories - proteinKcal - fatKcal)
        var carbGrams = remainingKcal / 4.0
        
        // If negative remainder due to high fat selection, reduce fat first down to lower bound, then clamp
        if proteinKcal + fatKcal > newCalories {
            let minFatKcal = newCalories * (Double(fatPercentRange.lowerBound) / 100.0)
            fatKcal = minFatKcal
            fatGrams = fatKcal / 9.0
            remainingKcal = max(0, newCalories - proteinKcal - fatKcal)
            carbGrams = remainingKcal / 4.0
        }
        
        let targets = MacroTargets(
            protein: proteinGrams,
            fats: max(20, min(150, fatGrams)),
            carbs: max(50, min(500, carbGrams))
        )
        return targets.validated
    }
    
    // MARK: - Persistence
    
    private func saveRecord(_ record: AutoTuneRecord) {
        var existing: [AutoTuneRecord] = loadRecords()
        existing.append(record)
        if let data = try? JSONEncoder().encode(existing) {
            defaults.set(data, forKey: recordsKey)
        }
    }
    
    func loadRecords() -> [AutoTuneRecord] {
        guard let data = defaults.data(forKey: recordsKey) else { return [] }
        if let decoded = try? JSONDecoder().decode([AutoTuneRecord].self, from: data) {
            return decoded
        }
        return []
    }
    
    func lastRecord() -> AutoTuneRecord? {
        return loadRecords().sorted { $0.createdAt > $1.createdAt }.first
    }
    
    func lastAdjustmentDeltaPercent() -> Int? {
        guard let rec = lastRecord() else { return nil }
        return Int(rec.adjustmentApplied * 100)
    }
    
    // MARK: - Gates
    
    private func isFeatureEnabled() -> Bool {
        if defaults.object(forKey: featureFlagKey) == nil { return true } // default true
        return defaults.bool(forKey: featureFlagKey)
    }
    
    private func isUserEligibleForAutoTune() -> Bool {
        let tier = SubscriptionManager.shared.currentTier
        switch tier {
        case .pro, .elite:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Haptics & Notifications
    
    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func sendNotification(title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus != .authorized {
            // Best-effort request; if denied, silently skip
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            print("❌ [AutoTune] Failed to schedule notification: \(error)")
            #endif
        }
    }

    // MARK: - Banner Dismissal
    func getBannerDismissUntil() -> Date? {
        return defaults.object(forKey: bannerDismissUntilKey) as? Date
    }
    
    func dismissBannerFor(days: Int) {
        if let until = Calendar.current.date(byAdding: .day, value: days, to: Date()) {
            defaults.set(until, forKey: bannerDismissUntilKey)
        }
    }
}


