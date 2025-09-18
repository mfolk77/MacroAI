import Foundation
import OSLog

enum Analytics {
    private static var subsystem: String {
        Bundle.main.bundleIdentifier ?? "comFolkTechAI.MacroAI-Pro"
    }

    private static let screenLog    = Logger(subsystem: subsystem, category: "screen")
    private static let featureLog   = Logger(subsystem: subsystem, category: "feature")
    private static let paywallLog   = Logger(subsystem: subsystem, category: "paywall")
    private static let revenueLog   = Logger(subsystem: subsystem, category: "revenue")
    private static let lifecycleLog = Logger(subsystem: subsystem, category: "lifecycle")
    private static let freemiumLog  = Logger(subsystem: subsystem, category: "freemium")

    static func screenView(_ name: String, context: [String: String] = [:]) {
        screenLog.log("screen_view name=\(name, privacy: .public) context=\(serialize(context), privacy: .private)")
    }

    static func featureUse(_ name: String, action: String, context: [String: String] = [:]) {
        featureLog.log("feature_use name=\(name, privacy: .public) action=\(action, privacy: .public) context=\(serialize(context), privacy: .private)")
    }

    static func paywallTriggered(source: String, feature: String) {
        paywallLog.log("paywall_trigger source=\(source, privacy: .public) feature=\(feature, privacy: .public)")
    }

    static func paywallResponse(_ response: String, source: String, context: [String: String] = [:]) {
        paywallLog.log("paywall_response action=\(response, privacy: .public) source=\(source, privacy: .public) context=\(serialize(context), privacy: .private)")
    }

    static func purchaseAttempt(productId: String) {
        revenueLog.log("purchase_attempt product=\(productId, privacy: .public)")
    }

    static func purchaseResult(productId: String, status: String) {
        revenueLog.log("purchase_result product=\(productId, privacy: .public) status=\(status, privacy: .public)")
    }

    static func subscriptionTierChanged(old: String, new: String) {
        revenueLog.log("subscription_tier_change from=\(old, privacy: .public) to=\(new, privacy: .public)")
    }

    static func lifecycle(_ event: String, context: [String: String] = [:]) {
        lifecycleLog.log("lifecycle event=\(event, privacy: .public) context=\(serialize(context), privacy: .private)")
    }

    private static func serialize(_ dict: [String: String]) -> String {
        guard !dict.isEmpty else { return "{}" }
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
           let s = String(data: data, encoding: .utf8) {
            return s
        }
        return "{}"
    }

    // MARK: - Freemium Helpers

    static func dailyLimitHit(mealCount: Int) {
        freemiumLog.log("daily_limit_hit meal_count=\(mealCount, privacy: .public)")
    }

    static func paywallShown(trigger: String) {
        freemiumLog.log("paywall_shown trigger=\(trigger, privacy: .public)")
    }

    static func paywallDismissed(action: String) {
        freemiumLog.log("paywall_dismissed action=\(action, privacy: .public)")
    }

    static func continueTrackingTapped() {
        freemiumLog.log("continue_tracking_tapped")
    }

    static func trialStarted(context: String) {
        freemiumLog.log("trial_started context=\(context, privacy: .public)")
    }

    static func trialConverted(day: Int) {
        freemiumLog.log("trial_converted day=\(day, privacy: .public)")
    }
}


