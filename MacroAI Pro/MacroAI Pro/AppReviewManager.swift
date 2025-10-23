import Foundation
import StoreKit

@MainActor
final class AppReviewManager {
    static let shared = AppReviewManager()
    private init() {}
    
    private let lastPromptDateKey = "appreview.lastPromptDate"
    private let hasReviewedKey = "appreview.hasReviewed"
    private let appFirstLaunchKey = "appreview.firstLaunchDate"
    private let minDaysBetweenPrompts: Int = 90
    private let minDaysBeforeReview: Int = 10 // 7 day trial + 3 days free usage
    
    func markReviewed() {
        UserDefaults.standard.set(true, forKey: hasReviewedKey)
    }
    
    func shouldPromptNow() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: hasReviewedKey) { return false }
        
        // Check if enough time has passed since first launch
        if let firstLaunch = defaults.object(forKey: appFirstLaunchKey) as? Date {
            let daysSinceLaunch = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
            if daysSinceLaunch < minDaysBeforeReview { return false }
        } else {
            // Set first launch date if not set
            defaults.set(Date(), forKey: appFirstLaunchKey)
            return false
        }
        
        // Check if enough time has passed since last prompt
        if let last = defaults.object(forKey: lastPromptDateKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            return days >= minDaysBetweenPrompts
        }
        return true
    }
    
    func requestReviewIfAppropriate(in scene: UIWindowScene?) {
        guard shouldPromptNow() else { return }
        if let scene = scene {
            SKStoreReviewController.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview()
        }
        UserDefaults.standard.set(Date(), forKey: lastPromptDateKey)
        // We cannot detect actual review completion; set a soft flag after first prompt.
        UserDefaults.standard.set(true, forKey: hasReviewedKey)
    }
}






