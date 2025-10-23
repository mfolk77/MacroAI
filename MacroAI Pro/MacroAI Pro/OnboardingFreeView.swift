import SwiftUI

struct OnboardingFreeView: View {
    @Environment(\.dismiss) private var dismiss
    var onDone: (() -> Void)?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundColor(.blue)

                Text("Welcome to MacroAI Coach")
                    .font(.title2).bold()
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Coach (7‑day trial): simple, educational guidance", systemImage: "flame.fill")
                    Label("Nutrition Mode: leaf icon in Chat for macro‑aware tips", systemImage: "leaf")
                    Label("Snap Food: 3 free scans/day", systemImage: "camera.fill")
                    Label("Upgrade anytime to unlock full access", systemImage: "crown.fill")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Button("Get Started") {
                    UserDefaults.standard.set(true, forKey: "OnboardingFreeSeen")
                    onDone?(); dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Quick Tour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Close") { dismiss() } } }
        }
    }
}








