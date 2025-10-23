import SwiftUI
import UserNotifications

struct CoachNudgeConfigView: View {
    @Environment(\.dismiss) private var dismiss

    // Enable toggles (persisted)
    @AppStorage("coachDailyEnabled") private var coachDailyEnabled: Bool = true
    @AppStorage("coachEveningEnabled") private var coachEveningEnabled: Bool = true
    @AppStorage("coachWeeklyEnabled") private var coachWeeklyEnabled: Bool = true
    @AppStorage("coachProteinEnabled") private var coachProteinEnabled: Bool = true
    @AppStorage("coachPrelogEnabled") private var coachPrelogEnabled: Bool = true

    // Time storage via UserDefaults keys used by CoachEngine
    @State private var dailyDate: Date = Date()
    @State private var eveningDate: Date = Date()
    @State private var proteinDate: Date = Date()
    @State private var prelogDate: Date = Date()

    let onScheduled: (([String]) -> Void)?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Check‑in")) {
                    Toggle("Enable Daily Nudge", isOn: $coachDailyEnabled)
                    DatePicker("Time", selection: Binding(
                        get: { dateFromStored(hourKey: "coachDailyHour", minuteKey: "coachDailyMinute", defaultHour: 9, defaultMinute: 0) },
                        set: { persist($0, hourKey: "coachDailyHour", minuteKey: "coachDailyMinute") }
                    ), displayedComponents: .hourAndMinute)
                    Text("A gentle habit check‑in to keep you on track.")
                        .font(.footnote).foregroundColor(.secondary)
                }

                Section(header: Text("Evening Plan Ahead")) {
                    Toggle("Enable Evening Nudge", isOn: $coachEveningEnabled)
                    DatePicker("Time", selection: Binding(
                        get: { dateFromStored(hourKey: "coachEveningHour", minuteKey: "coachEveningMinute", defaultHour: 19, defaultMinute: 0) },
                        set: { persist($0, hourKey: "coachEveningHour", minuteKey: "coachEveningMinute") }
                    ), displayedComponents: .hourAndMinute)
                    Text("Plan dinner or prep tomorrow’s breakfast to reduce decision fatigue.")
                        .font(.footnote).foregroundColor(.secondary)
                }

                Section(header: Text("Weekly Summary")) {
                    Toggle("Enable Weekly Summary (Sun)", isOn: $coachWeeklyEnabled)
                    Text("Sunday recap and quick adjustments for the week ahead.")
                        .font(.footnote).foregroundColor(.secondary)
                }

                Section(header: Text("Smart Timing")) {
                    Toggle("Protein by Lunch", isOn: $coachProteinEnabled)
                    DatePicker("Time", selection: Binding(
                        get: { dateFromStored(hourKey: "coachProteinHour", minuteKey: "coachProteinMinute", defaultHour: 11, defaultMinute: 30) },
                        set: { persist($0, hourKey: "coachProteinHour", minuteKey: "coachProteinMinute") }
                    ), displayedComponents: .hourAndMinute)
                    Text("Reminder to anchor protein by lunchtime for better satiety.")
                        .font(.footnote).foregroundColor(.secondary)

                    Toggle("Pre‑log Dinner", isOn: $coachPrelogEnabled)
                    DatePicker("Time", selection: Binding(
                        get: { dateFromStored(hourKey: "coachPrelogHour", minuteKey: "coachPrelogMinute", defaultHour: 16, defaultMinute: 30) },
                        set: { persist($0, hourKey: "coachPrelogHour", minuteKey: "coachPrelogMinute") }
                    ), displayedComponents: .hourAndMinute)
                    Text("Quickly log dinner before eating to avoid surprises.")
                        .font(.footnote).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Coach Nudges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save & Schedule") { saveAndSchedule() }
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear { preloadTimes() }
    }

    private func preloadTimes() {
        dailyDate = dateFromStored(hourKey: "coachDailyHour", minuteKey: "coachDailyMinute", defaultHour: 9, defaultMinute: 0)
        eveningDate = dateFromStored(hourKey: "coachEveningHour", minuteKey: "coachEveningMinute", defaultHour: 19, defaultMinute: 0)
        proteinDate = dateFromStored(hourKey: "coachProteinHour", minuteKey: "coachProteinMinute", defaultHour: 11, defaultMinute: 30)
        prelogDate = dateFromStored(hourKey: "coachPrelogHour", minuteKey: "coachPrelogMinute", defaultHour: 16, defaultMinute: 30)
    }

    private func dateFromStored(hourKey: String, minuteKey: String, defaultHour: Int, defaultMinute: Int) -> Date {
        let d = UserDefaults.standard
        let hour = d.object(forKey: hourKey) != nil ? d.integer(forKey: hourKey) : defaultHour
        let minute = d.object(forKey: minuteKey) != nil ? d.integer(forKey: minuteKey) : defaultMinute
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func persist(_ date: Date, hourKey: String, minuteKey: String) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let d = UserDefaults.standard
        d.set(comps.hour ?? 0, forKey: hourKey)
        d.set(comps.minute ?? 0, forKey: minuteKey)
    }

    private func saveAndSchedule() {
        // Schedule via CoachEngine honoring eligibility and toggles
        let eligible = SubscriptionManager.shared.currentTier != .basic || CoachTrialManager.shared.isWithinTrialWindow()
        guard eligible else {
            dismiss()
            return
        }
        CoachEngine.shared.startIfEligible(isEligible: eligible)
        // Summarize what was scheduled
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids: Set<String> = [
                "coach_daily_nudge",
                "coach_evening_nudge",
                "coach_weekly_summary",
                "coach_protein_by_lunch",
                "coach_prelog_dinner"
            ]
            let scheduled = requests.filter { ids.contains($0.identifier) }
            let names = scheduled.map { $0.identifier.replacingOccurrences(of: "coach_", with: "").replacingOccurrences(of: "_", with: " ") }
            DispatchQueue.main.async {
                onScheduled?(names)
                dismiss()
            }
        }
    }
}








