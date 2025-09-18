import Foundation
import Combine

final class UserSubscriptionManager: ObservableObject {
    static let shared = UserSubscriptionManager()

    @Published var isTrialing: Bool
    @Published var isPremium: Bool
    @Published var trialEndDate: Date?
    @Published var mealsLoggedToday: Int
    @Published var lastMealLogDate: Date?
    @Published var aiScansToday: Int
    @Published var lastScanDate: Date?

    private let defaults = UserDefaults.standard

    private init() {
        self.isPremium = defaults.bool(forKey: "USM_isPremium")
        self.isTrialing = defaults.bool(forKey: "USM_isTrialing")
        self.trialEndDate = defaults.object(forKey: "USM_trialEndDate") as? Date
        self.mealsLoggedToday = defaults.integer(forKey: "USM_mealsLoggedToday")
        self.lastMealLogDate = defaults.object(forKey: "USM_lastMealLogDate") as? Date
        self.aiScansToday = defaults.integer(forKey: "USM_aiScansToday")
        self.lastScanDate = defaults.object(forKey: "USM_lastScanDate") as? Date

        resetDailyCountIfNeeded(now: Date())
    }

    var trialDaysRemaining: Int {
        guard let end = trialEndDate else { return 0 }
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let startOfEnd = Calendar.current.startOfDay(for: end)
        return max(0, Calendar.current.dateComponents([.day], from: startOfToday, to: startOfEnd).day ?? 0)
    }

    func canLogMeal() -> Bool {
        if isPremium { return true }
        resetDailyCountIfNeeded(now: Date())
        return mealsLoggedToday < 2
    }

    func incrementMealCount() {
        resetDailyCountIfNeeded(now: Date())
        mealsLoggedToday += 1
        persist()
    }

    func resetDailyCount() {
        mealsLoggedToday = 0
        lastMealLogDate = Date()
        persist()
    }

    // MARK: - AI Scan Limits (Free: 3/day)
    func canScanToday() -> Bool {
        if isPremium { return true }
        resetDailyScanIfNeeded(now: Date())
        return aiScansToday < 3
    }

    func incrementScanCount() {
        resetDailyScanIfNeeded(now: Date())
        aiScansToday += 1
        persist()
    }

    private func resetDailyScanIfNeeded(now: Date) {
        guard let last = lastScanDate else {
            lastScanDate = now
            persist()
            return
        }
        if !Calendar.current.isDate(last, inSameDayAs: now) {
            aiScansToday = 0
            lastScanDate = now
            persist()
        }
    }

    private func resetDailyCountIfNeeded(now: Date) {
        guard let last = lastMealLogDate else {
            lastMealLogDate = now
            persist()
            return
        }
        if !Calendar.current.isDate(last, inSameDayAs: now) {
            mealsLoggedToday = 0
            lastMealLogDate = now
            persist()
        }
    }

    func startTrial(days: Int = 7) {
        isTrialing = true
        let end = Calendar.current.date(byAdding: .day, value: days, to: Date())
        trialEndDate = end
        persist()
        Analytics.trialStarted(context: "onboarding_completed")
    }

    func convertTrialToPremium() {
        let dayUsed: Int
        if let end = trialEndDate {
            let used = max(0, 7 - (Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0))
            dayUsed = used
        } else {
            dayUsed = 0
        }
        isTrialing = false
        isPremium = true
        persist()
        Analytics.trialConverted(day: dayUsed)
    }

    private func persist() {
        defaults.set(isPremium, forKey: "USM_isPremium")
        defaults.set(isTrialing, forKey: "USM_isTrialing")
        defaults.set(trialEndDate, forKey: "USM_trialEndDate")
        defaults.set(mealsLoggedToday, forKey: "USM_mealsLoggedToday")
        defaults.set(lastMealLogDate, forKey: "USM_lastMealLogDate")
        defaults.set(aiScansToday, forKey: "USM_aiScansToday")
        defaults.set(lastScanDate, forKey: "USM_lastScanDate")
    }
}


