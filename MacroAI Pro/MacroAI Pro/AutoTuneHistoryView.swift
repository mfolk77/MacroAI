import SwiftUI

struct AutoTuneHistoryView: View {
    let records: [AutoTuneRecord]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What is Auto‑Tune?")
                            .font(.headline)
                        Text("Auto‑Tune adapts your macro targets weekly based on your logs and selected diet plan (e.g., Keto, Diabetic, Standard). It gently adjusts your macro split and only changes calories when your intake trends notably off target. The percentage shows how much your daily calorie target changed this week.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                }
                
                ForEach(records) { rec in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Week \(format(rec.weekStart)) – \(format(rec.weekEnd))")
                                .font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            Text("\(Int(rec.adjustmentApplied * 100))%")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Text("New targets: P \(Int(rec.newTargets.protein)) • F \(Int(rec.newTargets.fats)) • C \(Int(rec.newTargets.carbs)) • \(rec.newTargets.estimatedCalories) kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Auto‑Tune History")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
    
    private func format(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: d)
    }
}


