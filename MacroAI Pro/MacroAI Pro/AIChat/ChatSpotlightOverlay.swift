import SwiftUI

struct ChatSpotlightOverlay: View {
    @Binding var isVisible: Bool
    @State private var step: Int = 0

    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { next() }

                // Position near top‑right where toolbar icons live
                VStack(alignment: .trailing, spacing: 14) {
                    if step == 0 {
                        callout(title: "Coach Nudges", text: "Tap the bell to set Daily, Evening, Weekly, Protein‑by‑Lunch, and Pre‑log Dinner times.")
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        callout(title: "Nutrition Mode", text: "Leaf icon toggles macro‑aware answers that use your macro targets.")
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    HStack(spacing: 10) {
                        if step == 1 {
                            Button("Done") { finish() }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button("Next") { next() }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .animation(.easeInOut(duration: 0.25), value: step)
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func callout(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title).font(.headline)
                Spacer()
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1.0)
        )
    }

    private func next() {
        if step == 0 { step = 1 } else { finish() }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "ChatSpotlightSeen")
        withAnimation { isVisible = false }
    }
}





