import SwiftUI
import SwiftData
import Foundation

struct CoachPanelView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Coach Mode")
                    .font(.title3).fontWeight(.semibold)
                Text("Streaks and daily nudges. Use Settings to toggle and send a test nudge.")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("Coach")
        }
    }
}