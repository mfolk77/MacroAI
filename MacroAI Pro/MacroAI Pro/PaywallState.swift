import Foundation

final class PaywallState: ObservableObject {
    static let shared = PaywallState()

    @Published var hasShownOnboardingPaywallThisSession = false
    @Published var hasShownLimitPaywallThisSession = false
    @Published var shownFeaturePaywalls: Set<String> = []

    private init() {}
}
