import SwiftUI

fileprivate func safePercentageText(_ progress: Double) -> String {
    // Handle NaN, infinity, and invalid values
    guard progress.isFinite else { return "0%" }
    
    let percentage = Int(progress * 100)
    return "\(percentage)%"
}

extension Notification.Name {
    static let triggerCelebration = Notification.Name("triggerCelebration")
}
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var entryStore: MacroEntryStore
    @StateObject private var storeKit = StoreKitManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @EnvironmentObject var premiumManager: PremiumManager
    
    @State private var showingAIChat = false
    @State private var showCelebration = false
    @State private var showingCamera = false
    @State private var showingManualEntry = false
    @State private var showingAddFood = false
    @State private var showingRecipes = false
    @State private var showingMarketplace = false
    @State private var showingSettings = false
    
    // Fun interactive states
    @State private var isShaking = false
    @State private var macroScale: [String: Double] = ["protein": 1.0, "carbs": 1.0, "fats": 1.0]
    @State private var celebrationMode = false
    @State private var powerMode = false
    @State private var showFortuneCookie = false
    @State private var dailyStreak = 0 // Will be calculated
    @State private var macroMood = "happy" // happy, hungry, satisfied, overflow
    @State private var pulseAnimation = false
    @State private var celebrationActive = false
    @State private var showPaywall = false
    @State private var usageCount = 0 // Track user usage for paywall triggers
    
    init() {
        // Initialize with a temporary context, will be set properly in onAppear
        let tempContainer = try! ModelContainer(for: MacroEntry.self, Recipe.self, NutritionCacheEntry.self)
        self._entryStore = StateObject(wrappedValue: MacroEntryStore(modelContext: tempContainer.mainContext))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                animatedBackground
                
                // Special Effects Layer
                SpecialEffectsView(celebrationActive: $celebrationActive)
                    .allowsHitTesting(false)
                
                VStack(spacing: 0) {
                    // Compact Header
                    compactHeader
                    
                    // Smaller Macro Plate
                    compactMacroPlate
                    
                    // Compact Progress Section
                    compactProgressSection
                    
                    // Compact Action Buttons
                    compactActionButtons
                    
                    // Compact AI Assistant
                    compactAIAssistant
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Set the proper ModelContext from environment
                entryStore.modelContext = modelContext
                startBreathingAnimation()
                updateMacroMood()
                calculateDailyStreak()
            }
        }
        .sheet(isPresented: $showingAIChat) {
            ChatView()
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(capturedImage: .constant(nil), macroEntryStore: entryStore)
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualEntryView(entryStore: entryStore)
        }
        .sheet(isPresented: $showingAddFood) {
            UnifiedFoodSearchView(macroEntryStore: entryStore, macroAIManager: ServiceFactory.createMockMacroAIManager())
        }
        .sheet(isPresented: $showingRecipes) {
            RecipeListView(modelContext: modelContext, entryStore: entryStore, storeKit: storeKit)
        }
        .sheet(isPresented: $showingMarketplace) {
            MarketplaceView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(macroEntryStore: entryStore)
                .environmentObject(storeKit)
        }
        .sheet(isPresented: $showPaywall) {
            AnnoyingPaywallView(isPresented: $showPaywall)
        }
    }
    
    // MARK: - Animated Background
    
    private var animatedBackground: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    themeManager.primaryColor.opacity(0.1),
                    Color.clear,
                    themeManager.secondaryColor.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Particles removed - too distracting
        }
    }
    
    // MARK: - Compact Header
    
    private var compactHeader: some View {
        VStack(spacing: 10) {
            HStack {
                // App Title
                HStack(spacing: 6) {
                    Text("Macro")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryColor)
                    
                    Text("AI")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(themeManager.secondaryColor)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                }
                
                Spacer()
                
                // Streak indicator
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("\(dailyStreak)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)
                
                // Settings button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .font(.title3)
                        .foregroundColor(themeManager.primaryColor)
                        .rotationEffect(.degrees(pulseAnimation ? 5 : 0))
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60) // Back to reasonable top padding
            
            // Compact mood indicator
            HStack {
                Image(systemName: moodIcon)
                    .foregroundColor(moodColor)
                    .font(.title3)
                
                Text(moodMessage)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(moodColor)
                
                Spacer()
                
                // Fortune cookie button - hidden during celebrations
                if !celebrationActive {
                    Button(action: { showFortuneCookie.toggle() }) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .rotationEffect(.degrees(showFortuneCookie ? 360 : 0))
                            .animation(.easeInOut(duration: 0.5), value: showFortuneCookie)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Compact Macro Plate
    
    private var compactMacroPlate: some View {
        VStack(spacing: 10) {
            ZStack {
                // Theme decorations around the plate
                themeDecorations
                
                // Smaller plate background
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [themeManager.primaryColor, themeManager.secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 200, height: 200) // Reduced from 280 to 200
                    .shadow(color: themeManager.primaryColor.opacity(0.3), radius: 8, x: 0, y: 3)
                    .scaleEffect(celebrationMode ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: celebrationMode)
                
                // Smaller Macro Icons
                VStack(spacing: 25) { // Reduced spacing from 40 to 25
                    // Fats (Butter) - Interactive
                    MacroFillIconView.fats(percentage: calculateFatPercentage())
                        .frame(width: 60, height: 60) // Reduced from 80 to 60
                        .scaleEffect(macroScale["fats"] ?? 1.0)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                macroScale["fats"] = 1.2
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    macroScale["fats"] = 1.0
                                }
                            }
                            triggerHapticFeedback(.light)
                        }
                    
                    HStack(spacing: 35) { // Reduced spacing from 50 to 35
                        // Protein (Turkey) - Interactive
                        MacroFillIconView.protein(percentage: calculateProteinPercentage())
                            .frame(width: 90, height: 90) // Reduced from 120 to 90
                            .scaleEffect(macroScale["protein"] ?? 1.0)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    macroScale["protein"] = 1.2
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                        macroScale["protein"] = 1.0
                                    }
                                }
                                triggerHapticFeedback(.light)
                            }
                        
                        // Carbs (Potato) - Interactive
                        MacroFillIconView.carbs(percentage: calculateCarbPercentage())
                            .frame(width: 60, height: 60) // Reduced from 80 to 60
                            .scaleEffect(macroScale["carbs"] ?? 1.0)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    macroScale["carbs"] = 1.2
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                        macroScale["carbs"] = 1.0
                                    }
                                }
                                triggerHapticFeedback(.light)
                            }
                    }
                }
            }
        }
        .frame(height: 300) // Reduced from 450 to 300
        .onTapGesture {
            // Celebration mode toggle
            withAnimation(.easeInOut(duration: 0.3)) {
                celebrationMode.toggle()
            }
            triggerHapticFeedback(.medium)
        }
    }
    
    // MARK: - Compact Progress Section
    
    private var compactProgressSection: some View {
        VStack(spacing: 12) { // Reduced spacing from 20 to 12
            // Today's Calories with Fun Animation
            HStack {
                Text("Today's Calories:")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(entryStore.todaysTotals.calories)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryColor)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12) // Reduced from 16 to 12
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeManager.primaryColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .onTapGesture {
                // Trigger celebration when tapping calories
                print("🎉 [HomeView] Triggering celebration via tap")
                themeManager.triggerCelebration()
                triggerHapticFeedback(.heavy)
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    celebrationMode = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        celebrationMode = false
                    }
                }
            }
            
            // Interactive Macro Chips
            HStack(spacing: 15) { // Reduced spacing from 20 to 15
                InteractiveMacroChip(
                    label: "Protein",
                    value: "\(entryStore.todaysTotals.protein)g",
                    color: .red,
                    progress: calculateProteinPercentage() / 100,
                    onTap: {
                        triggerHapticFeedback(.light)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            powerMode.toggle()
                        }
                    }
                )
                
                InteractiveMacroChip(
                    label: "Carbs",
                    value: "\(entryStore.todaysTotals.carbs)g",
                    color: .green,
                    progress: calculateCarbPercentage() / 100,
                    onTap: {
                        triggerHapticFeedback(.light)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            powerMode.toggle()
                        }
                    }
                )
                
                InteractiveMacroChip(
                    label: "Fat",
                    value: "\(entryStore.todaysTotals.fats)g",
                    color: .yellow,
                    progress: calculateFatPercentage() / 100,
                    onTap: {
                        triggerHapticFeedback(.light)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            powerMode.toggle()
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8) // Reduced from 10 to 8
    }
    
    // MARK: - Compact Action Buttons
    
    private var compactActionButtons: some View {
        VStack(spacing: 10) { // Reduced spacing from 16 to 10
            HStack(spacing: 12) { // Reduced spacing from 16 to 12
                // Snap Food Button with Camera Flash Effect
                PlayfulButton(
                    title: "Snap Food",
                    icon: "camera",
                    color: themeManager.primaryColor,
                    action: { 
                        showingCamera = true
                        trackTierUsage()
                        updateStreak()
                    },
                    effect: .cameraFlash
                )
                
                // Manual Entry Button with Typewriter Effect
                PlayfulButton(
                    title: "Manual Entry",
                    icon: "pencil",
                    color: themeManager.secondaryColor,
                    action: { 
                        showingManualEntry = true
                        trackTierUsage()
                        updateStreak()
                    },
                    effect: .typewriter
                )
            }
            
            // Food Search Button with Magnifying Glass Effect
            PlayfulButton(
                title: "Food Search",
                icon: "magnifyingglass",
                color: .blue,
                action: { 
                    showingAddFood = true
                    trackTierUsage()
                    updateStreak()
                },
                effect: .magnify
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8) // Reduced from 10 to 8
    }
    
    // MARK: - Compact AI Assistant
    
    private var compactAIAssistant: some View {
        VStack(spacing: 12) { // Reduced spacing from 20 to 12
            // AI Header with Personality
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(themeManager.primaryColor)
                        .font(.title3)
                        .rotationEffect(.degrees(pulseAnimation ? 5 : 0))
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Text("Macro AI")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryColor)
                }
                
                Spacer()
                
                // AI Status Badge
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Text("Elite")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.2))
                .cornerRadius(6)
            }
            
            // Fun AI Message
            Text(aiMessage)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10) // Reduced from 16 to 10
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
            
            // Interactive AI Button
            Button(action: { 
                showingAIChat = true
                updateStreak()
            }) {
                HStack {
                    Image(systemName: "message.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                        .rotationEffect(.degrees(pulseAnimation ? 5 : 0))
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Text("Ask MacroAI")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12) // Reduced from default to 12
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12) // Reduced from 20 to 12
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20) // Reduced from 40 to 20
    }
    
    // MARK: - Supporting Functions
    
    private func calculateProteinPercentage() -> Double {
        let targetProtein = Double(MacroTargets.current.protein)
        let currentProtein = Double(entryStore.todaysTotals.protein)
        
        // Prevent division by zero
        guard targetProtein > 0 else { return 0.0 }
        
        let percentage = (currentProtein / targetProtein) * 100
        return min(percentage.isFinite ? percentage : 0.0, 200)
    }
    
    private func calculateCarbPercentage() -> Double {
        let targetCarbs = Double(MacroTargets.current.carbs)
        let currentCarbs = Double(entryStore.todaysTotals.carbs)
        
        // Prevent division by zero
        guard targetCarbs > 0 else { return 0.0 }
        
        let percentage = (currentCarbs / targetCarbs) * 100
        return min(percentage.isFinite ? percentage : 0.0, 200)
    }
    
    private func calculateFatPercentage() -> Double {
        let targetFat = Double(MacroTargets.current.fats)
        let currentFat = Double(entryStore.todaysTotals.fats)
        
        // Prevent division by zero
        guard targetFat > 0 else { return 0.0 }
        
        let percentage = (currentFat / targetFat) * 100
        return min(percentage.isFinite ? percentage : 0.0, 200)
    }
    
    // MARK: - Testing Functions (Remove in production)
    
    private func triggerTestCelebration() {
        print("🎉 [HomeView] Triggering test celebration")
        NotificationCenter.default.post(name: .triggerCelebration, object: nil)
    }
    
    private func activatePrideTheme() {
        print("🌈 [HomeView] Activating Pride theme manually")
        if let prideTheme = themeManager.availableThemes.first(where: { $0.id == "pride_theme_2024" }) {
            themeManager.selectTheme(prideTheme)
        }
    }
    
    private func startBreathingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2.0)) {
                pulseAnimation.toggle()
            }
        }
    }
    
    private func updateMacroMood() {
        let proteinPct = calculateProteinPercentage()
        let carbsPct = calculateCarbPercentage()
        let fatsPct = calculateFatPercentage()
        
        let avgProgress = (proteinPct + carbsPct + fatsPct) / 3
        
        if avgProgress < 50 {
            macroMood = "hungry"
        } else if avgProgress < 80 {
            macroMood = "satisfied"
        } else if avgProgress < 120 {
            macroMood = "happy"
        } else {
            macroMood = "overflow"
        }
    }
    
    private func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Computed Properties
    
    private var moodIcon: String {
        switch macroMood {
        case "hungry": return "😋"
        case "satisfied": return "😊"
        case "happy": return "🎉"
        case "overflow": return "🤯"
        default: return "😊"
        }
    }
    
    private var moodColor: Color {
        switch macroMood {
        case "hungry": return .orange
        case "satisfied": return .green
        case "happy": return .blue
        case "overflow": return .red
        default: return .blue
        }
    }
    
    private var moodMessage: String {
        switch macroMood {
        case "hungry": return "Time to fuel up! 🍽️"
        case "satisfied": return "Looking good! ✨"
        case "happy": return "Crushing it! 🚀"
        case "overflow": return "Whoa there! 🎯"
        default: return "Ready to track! 📊"
        }
    }
    
    private var aiMessage: String {
        let proteinPct = calculateProteinPercentage()
        let carbsPct = calculateCarbPercentage()
        let fatsPct = calculateFatPercentage()
        
        if proteinPct < 50 {
            return "💪 Need more protein! Try adding some lean meat or eggs to your next meal."
        } else if carbsPct < 50 {
            return "🌾 Carbs are your friend! Consider adding some whole grains or fruits."
        } else if fatsPct < 50 {
            return "🥑 Healthy fats are essential! Avocados and nuts are great choices."
        } else if proteinPct > 120 || carbsPct > 120 || fatsPct > 120 {
            return "🎯 You're over your targets! Consider adjusting your portions."
        } else {
            return "🌟 You're doing amazing! Your macro balance looks perfect today."
        }
    }
    
    // MARK: - Theme Decorations (Disabled)
    
    private var themeDecorations: some View {
        // Theme decorations completely disabled - too distracting
        EmptyView()
    }
    
    // MARK: - Tier Usage Tracking
    
    private func trackTierUsage() {
        usageCount += 1
        
        // Show gentle upgrade prompt after significant usage for Basic tier users
        if usageCount >= 10 && premiumManager.currentTier == .basic {
            showUpgradePrompt()
        }
    }
    
    private func showUpgradePrompt() {
        // Show a gentle upgrade prompt for Basic tier users
        print("💡 [HomeView] Showing gentle upgrade prompt for Basic tier user")
    }
    
    private func isPremiumUser() -> Bool {
        // Check if user is on Pro or Elite tier
        return premiumManager.currentTier == .pro || premiumManager.currentTier == .elite || premiumManager.isTrialActive
    }
    
    // MARK: - Streak Tracking
    
    private func calculateDailyStreak() {
        let defaults = UserDefaults.standard
        let lastEntryDate = defaults.object(forKey: "lastEntryDate") as? Date ?? Date.distantPast
        let currentStreak = defaults.integer(forKey: "currentStreak")
        
        let calendar = Calendar.current
        let today = Date()
        
        // Check if user made an entry today
        if calendar.isDate(lastEntryDate, inSameDayAs: today) {
            // User already made an entry today, keep current streak
            dailyStreak = currentStreak
        } else if calendar.isDate(lastEntryDate, equalTo: calendar.date(byAdding: .day, value: -1, to: today) ?? today, toGranularity: .day) {
            // User made an entry yesterday, continue streak
            dailyStreak = currentStreak
        } else if calendar.isDate(lastEntryDate, equalTo: calendar.date(byAdding: .day, value: -2, to: today) ?? today, toGranularity: .day) {
            // User missed one day, reset streak
            dailyStreak = 0
            defaults.set(0, forKey: "currentStreak")
        } else {
            // User missed more than one day, reset streak
            dailyStreak = 0
            defaults.set(0, forKey: "currentStreak")
        }
    }
    
    private func updateStreak() {
        let defaults = UserDefaults.standard
        let currentStreak = defaults.integer(forKey: "currentStreak")
        let lastEntryDate = defaults.object(forKey: "lastEntryDate") as? Date ?? Date.distantPast
        
        // Only increment streak if it's a new day
        let calendar = Calendar.current
        if !calendar.isDate(lastEntryDate, inSameDayAs: Date()) {
            let newStreak = currentStreak + 1
            defaults.set(newStreak, forKey: "currentStreak")
            defaults.set(Date(), forKey: "lastEntryDate")
            
            dailyStreak = newStreak
            print("🔥 [HomeView] Streak updated to: \(newStreak)")
        } else {
            print("🔥 [HomeView] Streak already updated today, skipping")
        }
    }
}

// MARK: - Supporting Views

struct InteractiveMacroChip: View {
    let label: String
    let value: String
    let color: Color
    let progress: Double
    let onTap: () -> Void
    
    @State private var animatedProgress: Double = 0
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 3)
                
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        progress > 1.0 ? .red : color,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: animatedProgress)
                
                VStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(safePercentageText(progress))")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundColor(progress > 1.0 ? .red : .secondary)
                }
            }
            .frame(width: 50, height: 50)
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            onTap()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                animatedProgress = min(progress, 1.2)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = min(newValue, 1.2)
            }
        }
    }
}

struct PlayfulButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let effect: ButtonEffect
    
    @State private var isPressed = false
    @State private var showEffect = false
    
    enum ButtonEffect {
        case cameraFlash, typewriter, magnify
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
                showEffect = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showEffect = false
            }
            
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.title3)
                    .scaleEffect(showEffect ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: showEffect)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .overlay(
                        effectOverlay
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
    
    @ViewBuilder
    private var effectOverlay: some View {
        switch effect {
        case .cameraFlash:
            if showEffect {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.3))
                    .animation(.easeInOut(duration: 0.2), value: showEffect)
            }
        case .typewriter:
            if showEffect {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 2)
                    .animation(.easeInOut(duration: 0.2), value: showEffect)
            }
        case .magnify:
            if showEffect {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .scaleEffect(showEffect ? 1.5 : 0.5)
                    .opacity(showEffect ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: showEffect)
            }
        }
    }
}

#Preview {
    HomeView() 
} 

