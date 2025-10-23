import SwiftUI

struct OnboardingProView: View {
    @Environment(\.dismiss) private var dismiss
    var onDone: (() -> Void)?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill").foregroundColor(.yellow)
                        Text("Welcome to Premium")
                            .font(.title2).bold()
                    }

                    GroupBox(label: Label("Coach", systemImage: "flame.fill")) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Daily, Evening, Weekly + smart nudges.")
                            Text("Tap the bell in Chat to set times.")
                        }
                        .font(.subheadline)
                    }

                    GroupBox(label: Label("Nutrition Mode", systemImage: "leaf")) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Leaf icon in Chat. Answers use your macros and targets.")
                            Text("Great for meal planning and grocery consolidation.")
                        }
                        .font(.subheadline)
                    }

                    GroupBox(label: Label("Auto‑Tune", systemImage: "bolt.circle")) {
                        Text("Weekly macro adjustments based on progress; view history from Home.")
                            .font(.subheadline)
                    }

                    Spacer(minLength: 12)
                    Button("Start Coaching") {
                        UserDefaults.standard.set(true, forKey: "OnboardingProSeen")
                        onDone?(); dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Premium Tour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Close") { dismiss() } } }
        }
    }
}





