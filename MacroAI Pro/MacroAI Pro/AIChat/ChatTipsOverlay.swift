import SwiftUI

struct ChatTipsOverlay: View {
    var onClose: () -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "bell.badge").foregroundColor(.orange)
                    Text("Coach Nudges")
                        .font(.headline)
                }
                Text("Tap the bell (top‑right) to set Daily, Evening, Weekly, Protein‑by‑Lunch, and Pre‑log Dinner nudges.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    Image(systemName: "leaf").foregroundColor(.green)
                    Text("Nutrition Mode")
                        .font(.headline)
                }
                Text("Leaf icon toggles macro‑aware answers that use your macro targets.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
                Button("Got it") { onClose() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Coach Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Close") { onClose() } } }
        }
    }
}





