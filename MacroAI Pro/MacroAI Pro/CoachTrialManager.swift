import Foundation

@MainActor
final class CoachTrialManager {
    static let shared = CoachTrialManager()
    private init() {}

    private let trialStartKey = "coachTrial.startDate"
    private let trialDaysKey = "coachTrial.lengthDays"

    @discardableResult
    func startIfNeeded(days: Int = 7) -> Bool {
        let d = UserDefaults.standard
        if d.object(forKey: trialStartKey) == nil {
            d.set(Date(), forKey: trialStartKey)
            d.set(days, forKey: trialDaysKey)
            Analytics.featureUse("coach", action: "trial_started")
            return true
        }
        return false
    }

    func isWithinTrialWindow(days: Int = 7) -> Bool {
        let d = UserDefaults.standard
        let start = d.object(forKey: trialStartKey) as? Date
        let configuredDays = d.integer(forKey: trialDaysKey)
        let window = configuredDays > 0 ? configuredDays : days
        guard let start = start else { return false }
        guard let end = Calendar.current.date(byAdding: .day, value: window, to: start) else { return false }
        return Date() < end
    }

    func daysRemaining(defaultDays: Int = 7) -> Int {
        let d = UserDefaults.standard
        let start = d.object(forKey: trialStartKey) as? Date
        let configuredDays = d.integer(forKey: trialDaysKey)
        let window = configuredDays > 0 ? configuredDays : defaultDays
        guard let start = start, let end = Calendar.current.date(byAdding: .day, value: window, to: start) else { return 0 }
        let comps = Calendar.current.dateComponents([.day], from: Date(), to: end)
        return max(0, comps.day ?? 0)
    }

    func reset() {
        let d = UserDefaults.standard
        d.removeObject(forKey: trialStartKey)
        d.removeObject(forKey: trialDaysKey)
    }
}

extension Notification.Name {
    static let coachBadgeUpdated = Notification.Name("CoachBadgeUpdatedNotification")
}


