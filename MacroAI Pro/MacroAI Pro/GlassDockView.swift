import SwiftUI

struct GlassDockView: View {
    enum DockAction { case coach, upgrade, marketplace }
    
    let showUpgrade: Bool
    let autoHide: Bool
    let onAction: (DockAction) -> Void
    @Binding var isVisible: Bool
    let listBadgeCount: Int
    
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false
    @State private var autoHideWorkItem: DispatchWorkItem?
    private let autoHideDelay: TimeInterval = 5.0
    
    var body: some View {
        HStack(spacing: 14) {
            dockButton(system: "bag.fill", label: "Market") { onAction(.marketplace) }
            if showUpgrade { dockButton(system: "crown.fill", label: "Upgrade") { onAction(.upgrade) } }
        }
        .padding(.horizontal, expanded ? 18 : 14)
        .padding(.vertical, 12)
        .background(
            reduceTransparency ? AnyShapeStyle(Color(.systemGray6)) : AnyShapeStyle(.ultraThinMaterial)
        , in: Capsule())
        .overlay(
            ZStack {
                // Edge separation strokes
                Capsule().stroke(Color.white.opacity(reduceTransparency ? 0 : 0.08), lineWidth: 0.5)
                Capsule().stroke(Color.black.opacity(reduceTransparency ? 0 : 0.03), lineWidth: 0.5)
                // Top specular highlight
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(reduceTransparency ? 0 : 0.06), Color.white.opacity(0)],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .blendMode(.plusLighter)
                // Subtle bottom inner shade for depth
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(reduceTransparency ? 0 : 0.03), Color.black.opacity(0)],
                            startPoint: .bottom,
                            endPoint: .center
                        )
                    )
                    .blendMode(.multiply)
            }
            .allowsHitTesting(false)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        // Removed parent tap gesture to ensure dock buttons receive taps without interference
        .padding(.bottom, 10)
        .padding(.horizontal)
        .offset(y: autoHide && !isVisible ? 160 : 0)
        .opacity(autoHide && !isVisible ? 0.001 : 1)
        .allowsHitTesting(!(autoHide && !isVisible))
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .onAppear {
            showAndScheduleHide()
        }
        .onChange(of: autoHide) { _, _ in
            showAndScheduleHide()
        }
        .onChange(of: isVisible) { _, newValue in
            // Only schedule hide when becoming visible; avoids bounce loops
            if newValue { showAndScheduleHide() }
        }
    }
    
    @ViewBuilder
    private func dockButton(system: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            isVisible = true
            showAndScheduleHide()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: system)
                    .font(.headline)
                if expanded {
                    Text(label)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, expanded ? 12 : 10)
            .padding(.vertical, 12) // ≥44pt hit target
            .background(
                Capsule().fill(reduceTransparency ? Color(.systemGray5) : Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .accessibilityLabel(Text(label))
    }

    @ViewBuilder
    private func dockButtonWithBadge(system: String, label: String, badge: Int, action: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            dockButton(system: system, label: label, action: action)
            if badge > 0 {
                Text(badge > 99 ? "99+" : "\(badge)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.red, in: Capsule())
                    .offset(x: 10, y: -8)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(Text(label))
    }

    private func showAndScheduleHide() {
        guard autoHide else { return }
        isVisible = true
        autoHideWorkItem?.cancel()
        let work = DispatchWorkItem {
            if UIAccessibility.isVoiceOverRunning {
                // Keep visible during VoiceOver usage for accessibility
                return
            }
            withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.25)) {
                isVisible = false
            }
        }
        autoHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + autoHideDelay, execute: work)
    }
}

