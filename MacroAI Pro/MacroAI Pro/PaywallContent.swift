import SwiftUI

enum PaywallKind {
    case onboarding
    case dailyLimit
    case feature(name: String)
}

struct DynamicPaywallView: View {
    let kind: PaywallKind
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            switch kind {
            case .onboarding:
                Text("Ready to Supercharge Your Nutrition Journey?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("Start your 7-day free trial and unlock unlimited AI scanning plus premium features")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                featuresList([
                    "Unlimited AI food scanning",
                    "Advanced diet plans (Keto, Mediterranean, High-Protein)",
                    "Premium themes & customization",
                    "Detailed progress analytics",
                    "AI meal planning suggestions"
                ])
                trialTerms
                primary("Start Free Trial", action: onPrimary)
                secondary("Maybe Later", action: onSecondary)
            case .dailyLimit:
                Text("Daily Scan Limit Reached")
                    .font(.title2.bold())
                Text("You've used your 3 free AI scans today. Upgrade to scan unlimited meals!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                featuresList([
                    "Continue tracking today with unlimited scanning",
                    "Access detailed nutrition analytics",
                    "Unlock all premium diet plans",
                    "Get premium themes & customization"
                ])
                Text("Reset at midnight • Premium unlocks unlimited scanning")
                    .font(.caption)
                    .foregroundColor(.secondary)
                primary("Continue Tracking", action: onPrimary)
                secondary("Wait Until Tomorrow", action: onSecondary)
            case .feature(let name):
                Text("Premium Feature")
                    .font(.title2.bold())
                Text("Unlock \(name) and all premium features with your free trial")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                primary("Unlock Premium", action: onPrimary)
                secondary("Not Now", action: onSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .padding()
    }

    private func featuresList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("✅")
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trialTerms: some View {
        VStack(spacing: 4) {
            Text("$9.99/month after trial")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("7-Day Free Trial • Cancel Anytime in Settings")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).fontWeight(.semibold).frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private func secondary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}


