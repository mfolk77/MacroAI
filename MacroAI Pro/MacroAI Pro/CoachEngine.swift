import Foundation
import UserNotifications

final class CoachEngine {
    static let shared = CoachEngine()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private let dailyNudgeIdentifier = "coach_daily_nudge"
    private let eveningNudgeIdentifier = "coach_evening_nudge"
    private let weeklySummaryIdentifier = "coach_weekly_summary"
    private let notifDeniedPostedKey = "coach_notif_denied_posted"
    private let abVariantKey = "coach_ab_variant"
    static let openChatWithPrompt = Notification.Name("CoachOpenChatWithPrompt")

    private init() {}

    func startIfEligible(isEligible: Bool) {
        guard isEligible, isFeatureEnabledForUser() else { return }
        // Basic users allowed only during 7‑day trial
        #if DEBUG
        print("[CoachEngine] Trial active? \(CoachTrialManager.shared.isWithinTrialWindow())")
        #endif
        requestNotificationAuthorizationIfNeeded { [weak self] granted in
            guard let self = self else { return }
            #if DEBUG
            print("[CoachEngine] Notification permission granted=\(granted)")
            #endif
            if granted {
                // Ensure badge can show after (re)scheduling
                self.defaults.set(false, forKey: "coach_badge_override_zero")
                // Read user-configured times with sensible defaults
                let d = self.defaults
                let dailyHour = d.object(forKey: "coachDailyHour") != nil ? d.integer(forKey: "coachDailyHour") : 9
                let dailyMinute = d.object(forKey: "coachDailyMinute") != nil ? d.integer(forKey: "coachDailyMinute") : 0
                let eveningHour = d.object(forKey: "coachEveningHour") != nil ? d.integer(forKey: "coachEveningHour") : 19
                let eveningMinute = d.object(forKey: "coachEveningMinute") != nil ? d.integer(forKey: "coachEveningMinute") : 0
                let proteinHour = d.object(forKey: "coachProteinHour") != nil ? d.integer(forKey: "coachProteinHour") : 11
                let proteinMinute = d.object(forKey: "coachProteinMinute") != nil ? d.integer(forKey: "coachProteinMinute") : 30
                let prelogHour = d.object(forKey: "coachPrelogHour") != nil ? d.integer(forKey: "coachPrelogHour") : 16
                let prelogMinute = d.object(forKey: "coachPrelogMinute") != nil ? d.integer(forKey: "coachPrelogMinute") : 30

                let dailyEnabled = d.object(forKey: "coachDailyEnabled") as? Bool ?? true
                let eveningEnabled = d.object(forKey: "coachEveningEnabled") as? Bool ?? true
                let weeklyEnabled = d.object(forKey: "coachWeeklyEnabled") as? Bool ?? true
                let proteinEnabled = d.object(forKey: "coachProteinEnabled") as? Bool ?? true
                let prelogEnabled = d.object(forKey: "coachPrelogEnabled") as? Bool ?? true

                if dailyEnabled { self.scheduleDailyNudge(hour: dailyHour, minute: dailyMinute) }
                if eveningEnabled { self.scheduleEveningReminder(hour: eveningHour, minute: eveningMinute) }
                if weeklyEnabled { self.scheduleWeeklySummary(weekday: 1, hour: dailyHour, minute: dailyMinute) }
                if proteinEnabled { self.scheduleProteinByLunch(hour: proteinHour, minute: proteinMinute) }
                if prelogEnabled { self.schedulePrelogDinner(hour: prelogHour, minute: prelogMinute) }
                NotificationCenter.default.post(name: .coachBadgeUpdated, object: nil)
            }
            self.bumpStreakIfNewDay()
        }
    }

    // MARK: - Feature Flag
    private func isFeatureEnabledForUser() -> Bool {
        if defaults.object(forKey: "coachModeEnabled") == nil {
            defaults.set(true, forKey: "coachModeEnabled")
        }
        return defaults.bool(forKey: "coachModeEnabled")
    }

    // MARK: - Notifications
    private func requestNotificationAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                if !self.defaults.bool(forKey: self.notifDeniedPostedKey) {
                    self.defaults.set(true, forKey: self.notifDeniedPostedKey)
                    NotificationCenter.default.post(name: Notification.Name("CoachNotificationsDenied"), object: nil)
                }
                completion(false)
            case .notDetermined:
                self.notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }

    func scheduleDailyNudge(hour: Int, minute: Int) {
        guard canSchedule(identifier: dailyNudgeIdentifier, minInterval: 7200) else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailyNudgeIdentifier])

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        let copy = selectCopyVariant(
            a: (title: "Today's 1% better", body: "Log a meal or scan a food to keep your streak alive."),
            b: (title: "Keep your streak 🔥", body: "One small action today: log a meal or scan a food.")
        )
        content.title = copy.title
        content.body = copy.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: dailyNudgeIdentifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            #if DEBUG
            if let error = error {
                print("[CoachEngine] Failed to schedule daily nudge: \(error)")
            } else {
                print("[CoachEngine] Daily nudge scheduled at \(hour):\(String(format: "%02d", minute))")
            }
            #endif
        }
        markScheduledNow(identifier: dailyNudgeIdentifier)
        Analytics.featureUse("coach_nudge", action: "daily")
    }

    func scheduleEveningReminder(hour: Int, minute: Int) {
        guard canSchedule(identifier: eveningNudgeIdentifier, minInterval: 7200) else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [eveningNudgeIdentifier])

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        let copy = selectCopyVariant(
            a: (title: "Evening check‑in", body: "Close the loop: add dinner or a quick snack."),
            b: (title: "Finish strong", body: "Two taps to log dinner and keep momentum.")
        )
        content.title = copy.title
        content.body = copy.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: eveningNudgeIdentifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            #if DEBUG
            if let error = error {
                print("[CoachEngine] Failed to schedule evening nudge: \(error)")
            } else {
                print("[CoachEngine] Evening nudge scheduled at \(hour):\(String(format: "%02d", minute))")
            }
            #endif
        }
        markScheduledNow(identifier: eveningNudgeIdentifier)
        Analytics.featureUse("coach_nudge", action: "evening")
    }

    func scheduleWeeklySummary(weekday: Int, hour: Int, minute: Int) {
        guard canSchedule(identifier: weeklySummaryIdentifier, minInterval: 7200) else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [weeklySummaryIdentifier])

        var components = DateComponents()
        components.weekday = weekday // 1=Sunday
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Weekly check‑in"
        content.body = "Review your week, celebrate streaks, and set a tiny goal."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: weeklySummaryIdentifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            #if DEBUG
            if let error = error {
                print("[CoachEngine] Failed to schedule weekly summary: \(error)")
            } else {
                print("[CoachEngine] Weekly summary scheduled (weekday=\(weekday)) at \(hour):\(String(format: "%02d", minute))")
            }
            #endif
        }
        markScheduledNow(identifier: weeklySummaryIdentifier)
        Analytics.featureUse("coach_nudge", action: "weekly")
    }

    // MARK: - Smart Timing Nudges
    private func scheduleProteinByLunch(hour: Int, minute: Int) {
        var date = DateComponents(); date.hour = hour; date.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Protein by lunch"
        content.body = "Want ideas to hit your protein before 12? Tap to plan together."
        content.sound = .default
        let id = "coach_protein_by_lunch"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        notificationCenter.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        NotificationCenter.default.post(name: .coachBadgeUpdated, object: nil)
    }
    
    private func schedulePrelogDinner(hour: Int, minute: Int) {
        var date = DateComponents(); date.hour = hour; date.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Pre‑log dinner"
        content.body = "Two minutes now saves stress later. Tap to pre‑plan a balanced dinner."
        content.sound = .default
        let id = "coach_prelog_dinner"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        notificationCenter.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        NotificationCenter.default.post(name: .coachBadgeUpdated, object: nil)
    }

    // MARK: - Gentle Course Correction
    func suggestLighterDinnerPrompt(caloriesTarget: Int = 600, proteinTarget: Int = 35) {
        let prompt = "I’m a bit over calories at lunch. Suggest a lighter dinner around \(caloriesTarget) calories with ~\(proteinTarget)g protein. Give 3 options and a simple grocery list."
        NotificationCenter.default.post(name: CoachEngine.openChatWithPrompt, object: prompt)
    }

    func promptProteinIdeas() {
        let prompt = "Give me 5 quick high‑protein snack ideas under 250 calories."
        NotificationCenter.default.post(name: CoachEngine.openChatWithPrompt, object: prompt)
    }

    func promptPrelogDinner() {
        let prompt = "Help me plan a balanced dinner ~550 calories with ~35–40g protein. 3 options."
        NotificationCenter.default.post(name: CoachEngine.openChatWithPrompt, object: prompt)
    }

    // MARK: - Streaks
    func recordUserActionAndUpdateStreak() {
        defaults.set(Date(), forKey: "lastEntryDate")
        let calendar = Calendar.current
        let lastIncrement = defaults.object(forKey: "lastStreakIncrementDate") as? Date ?? .distantPast
        if !calendar.isDate(lastIncrement, inSameDayAs: Date()) {
            let current = defaults.integer(forKey: "currentStreak")
            defaults.set(current + 1, forKey: "currentStreak")
            defaults.set(Date(), forKey: "lastStreakIncrementDate")
            #if DEBUG
            print("[CoachEngine] Streak incremented to: \(current + 1)")
            #endif
        }
    }

    func bumpStreakIfNewDay() {
        // Placeholder for future logic if we add passive adjustments; currently no-op.
        // HomeView already maintains streaks using the same defaults keys.
    }

    // MARK: - A/B Copy
    private func selectCopyVariant(a: (title: String, body: String), b: (title: String, body: String)) -> (title: String, body: String) {
        var variant = defaults.string(forKey: abVariantKey)
        if variant == nil {
            variant = Bool.random() ? "A" : "B"
            defaults.set(variant, forKey: abVariantKey)
        }
        return variant == "A" ? a : b
    }

    // MARK: - Debug
    func sendTestNudgeNow() {
        requestNotificationAuthorizationIfNeeded { [weak self] granted in
            guard let self = self else { return }
            #if DEBUG
            print("[CoachEngine] sendTestNudgeNow granted=\(granted)")
            #endif
            guard granted else {
                if !self.defaults.bool(forKey: self.notifDeniedPostedKey) {
                    self.defaults.set(true, forKey: self.notifDeniedPostedKey)
                    NotificationCenter.default.post(name: Notification.Name("CoachNotificationsDenied"), object: nil)
                }
                return
            }
            // Bypass quiet hours and dedupe for explicit tester action
            let content = UNMutableNotificationContent()
            content.title = "Test Nudge"
            content.body = "This is a test notification from CoachEngine."
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            self.notificationCenter.add(request) { error in
                #if DEBUG
                if let error = error { print("[CoachEngine] Failed to deliver test nudge: \(error)") }
                else { print("[CoachEngine] Test nudge delivered immediately") }
                #endif
            }
            Analytics.featureUse("coach_nudge", action: "test")
        }
    }

    // MARK: - Quiet hours & Dedupe
    private func isWithinQuietHours() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 22 || hour < 7
    }

    private func canSchedule(identifier: String, minInterval: TimeInterval) -> Bool {
        let key = "coach_last_sched_\(identifier)"
        let last = defaults.object(forKey: key) as? Date ?? .distantPast
        return Date().timeIntervalSince(last) >= minInterval
    }

    private func markScheduledNow(identifier: String) {
        let key = "coach_last_sched_\(identifier)"
        defaults.set(Date(), forKey: key)
    }

#if DEBUG
    // MARK: - Test helpers (DEBUG only)
    func _isQuietHour(hour: Int) -> Bool { return hour >= 22 || hour < 7 }
    func _setLastScheduled(identifier: String, date: Date) {
        let key = "coach_last_sched_\(identifier)"
        defaults.set(date, forKey: key)
    }
    func _canScheduleForTest(identifier: String, minInterval: TimeInterval) -> Bool {
        return canSchedule(identifier: identifier, minInterval: minInterval)
    }
#endif
}


