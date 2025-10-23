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
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @AppStorage("showDock") private var showDock: Bool = true
    @AppStorage("dockAutoHide") private var dockAutoHide: Bool = true
    @State private var dockVisible: Bool = true
    
    @State private var showingAIChat = false
    @State private var showCelebration = false
    @State private var showingCamera = false
    @State private var showingManualEntry = false
    @State private var showingAddFood = false
    @State private var showingRecipes = false
    @State private var showingMarketplace = false
    @State private var showingSettings = false
    @State private var showOnboardingFree = false
    @State private var showOnboardingPro = false
    @State private var showInteractiveDemo = false
    @State private var showDemoResults = false
    @State private var demoMacroEntry: [String: Any] = [:]
    
    
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
    @State private var showingCoachPanel = false
    @State private var showingAutoTuneHistory = false
    @State private var notifDeniedAlert: Bool = false
    
    init() {
        // Initialize with a temporary context, will be set properly in onAppear
        do {
            let tempContainer = try ModelContainer(for: MacroEntry.self, Recipe.self, NutritionCacheEntry.self)
            self._entryStore = StateObject(wrappedValue: MacroEntryStore(modelContext: tempContainer.mainContext))
        } catch {
            // Fallback to an in-memory container if the main one fails (no crash)
            if let fallbackContainer = try? ModelContainer(for: MacroEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) {
                self._entryStore = StateObject(wrappedValue: MacroEntryStore(modelContext: fallbackContainer.mainContext))
            } else {
                // Last resort: create minimal in-memory container
                let minimal = try! ModelContainer(for: MacroEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                self._entryStore = StateObject(wrappedValue: MacroEntryStore(modelContext: minimal.mainContext))
            }
        }
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
                    
                    // Auto‑Tune banner (top, week of change only)
                    if let rec = AutoTuneEngine.shared.lastRecord(), shouldShowAutoTuneBanner(rec) {
                        autoTuneBanner(delta: Int(rec.adjustmentApplied * 100))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    
                    // Smaller Macro Plate
                    compactMacroPlate
                    
                    // Compact Progress Section
                    compactProgressSection
                    
                    // Compact Action Buttons
                    compactActionButtons
                    
                    // Compact AI Assistant
                    compactAIAssistant
                }
                .padding(.bottom, 80)
                
                // Glass Dock pinned at bottom
                if showDock {
                    VStack {
                        Spacer()
                        GlassDockView(
                            showUpgrade: subscriptionManager.currentTier == .basic,
                            autoHide: dockAutoHide,
                            onAction: handleDockAction,
                            isVisible: $dockVisible,
                            listBadgeCount: 0
                        )
                        .padding(.bottom, 8)
                    }
                    .zIndex(3000)
                    .ignoresSafeArea(edges: .bottom)
                    
                    // Demo Results Overlay
                    if showDemoResults {
                        VStack {
                            Spacer()
                            demoResultsCard
                                .padding(.horizontal, 20)
                                .padding(.bottom, 100)
                    }
                    .zIndex(3001)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.5), value: showDemoResults)
                }
                
                    
                    // Reveal hotspot at the bottom edge when auto-hide is enabled
                    if dockAutoHide && !dockVisible {
                        Color.clear
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                ZStack(alignment: .bottom) {
                                    // Swipe reveal zone
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 64)
                                        .frame(maxWidth: .infinity)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 5, coordinateSpace: .local)
                                                .onEnded { value in
                                                    if value.translation.height < -8 {
                                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                                            dockVisible = true
                                                        }
                                                    }
                                                }
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                                dockVisible = true
                                            }
                                        }
                                    
                                    // Chevron handle affordance
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                                dockVisible = true
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "chevron.up")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(.ultraThinMaterial, in: Capsule())
                                            .overlay(
                                                Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                        Spacer()
                                    }
                                    .padding(.bottom, 24)
                                }
                                .contentShape(Rectangle())
                                .allowsHitTesting(true)
                                , alignment: .bottom
                            )
                            .zIndex(4000)
                            .allowsHitTesting(true)
                            .ignoresSafeArea(edges: .bottom)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Set the proper ModelContext from environment
                entryStore.modelContext = modelContext
                Task { await entryStore.fetchEntries() }
                startBreathingAnimation()
                updateMacroMood()
                calculateDailyStreak()
                Analytics.screenView("home")
                // Defer onboarding until final phase
                // Coach Mode (no UI change): gated by SubscriptionManager tier + trial
                let isEligible = subscriptionManager.currentTier != .basic || CoachTrialManager.shared.isWithinTrialWindow()
                CoachEngine.shared.startIfEligible(isEligible: isEligible)
                // Weekly Auto‑Tune: run if due (feature-flagged and Pro/Elite only)
                #if !DEBUG || DEBUG_AUTOTUNE_TEST
                Task { await AutoTuneEngine.shared.runWeeklyAdjustmentIfDue(modelContext: modelContext) }
                #endif
                #if DEBUG
                // Ensure a recent record exists in DEBUG so the banner can appear for testing
                Task { await AutoTuneEngine.shared.seedDebugRecordIfMissing(modelContext: modelContext) }
                #endif
                // Coach → Chat handoff listener
                NotificationCenter.default.addObserver(forName: CoachEngine.openChatWithPrompt, object: nil, queue: .main) { note in
                    guard let prompt = note.object as? String else { return }
                    showingAIChat = true
                    // Delay one runloop to allow sheet to present before assigning
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Not directly accessible here; pass via defaults as transient inbox
                        UserDefaults.standard.set(prompt, forKey: "ChatInitialPromptInbox")
                        UserDefaults.standard.synchronize()
                    }
                }
                // Notifications denied alert once per session
                NotificationCenter.default.addObserver(forName: Notification.Name("CoachNotificationsDenied"), object: nil, queue: .main) { _ in
                    notifDeniedAlert = true
                }
                // Interactive demo notification listener
                NotificationCenter.default.addObserver(forName: Notification.Name("ShowInteractiveDemo"), object: nil, queue: .main) { _ in
                    showInteractiveDemo = true
                }
                
                // Resume interactive demo notification listener
                NotificationCenter.default.addObserver(forName: Notification.Name("ResumeInteractiveDemo"), object: nil, queue: .main) { _ in
                    showInteractiveDemo = true
                }
                
                // Demo callback notification listeners (remove old ones first)
                NotificationCenter.default.removeObserver(self, name: Notification.Name("OpenCameraFromDemo"), object: nil)
                NotificationCenter.default.removeObserver(self, name: Notification.Name("OpenCoachFromDemo"), object: nil)
                NotificationCenter.default.removeObserver(self, name: Notification.Name("OpenFoodSearchFromDemo"), object: nil)
                NotificationCenter.default.removeObserver(self, name: Notification.Name("OpenSettingsFromDemo"), object: nil)
                
                NotificationCenter.default.addObserver(forName: Notification.Name("OpenCameraFromDemo"), object: nil, queue: .main) { _ in
                    showingCamera = true
                }
                NotificationCenter.default.addObserver(forName: Notification.Name("OpenCoachFromDemo"), object: nil, queue: .main) { _ in
                    showingAIChat = true
                }
                NotificationCenter.default.addObserver(forName: Notification.Name("OpenFoodSearchFromDemo"), object: nil, queue: .main) { _ in
                    showingAddFood = true
                }
                NotificationCenter.default.addObserver(forName: Notification.Name("OpenSettingsFromDemo"), object: nil, queue: .main) { _ in
                    showingSettings = true
                }
                
                // Check for demo results
                if UserDefaults.standard.bool(forKey: "ShowDemoResults") {
                    if let demoEntry = UserDefaults.standard.object(forKey: "DemoMacroEntry") as? [String: Any] {
                        demoMacroEntry = demoEntry
                        showDemoResults = true
                    }
                }
                
                // Listen for demo results notification
                NotificationCenter.default.addObserver(forName: Notification.Name("ShowDemoResults"), object: nil, queue: .main) { notification in
                    if let demoEntry = notification.object as? [String: Any] {
                        demoMacroEntry = demoEntry
                        showDemoResults = true
                    }
                }
                
                
                // Periodic one-time review prompt after app has been used
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    AppReviewManager.shared.requestReviewIfAppropriate(in: scene)
                } else {
                    AppReviewManager.shared.requestReviewIfAppropriate(in: nil)
                }
            }
        }
        .sheet(isPresented: $showingAIChat) {
            let inbox = UserDefaults.standard.string(forKey: "ChatInitialPromptInbox")
            ChatView(initialPrompt: inbox)
                .onDisappear {
                    UserDefaults.standard.removeObject(forKey: "ChatInitialPromptInbox")
                }
        }
        .sheet(isPresented: $showOnboardingFree) { OnboardingFreeView(onDone: { showOnboardingFree = false }) }
        .sheet(isPresented: $showOnboardingPro) { OnboardingProView(onDone: { showOnboardingPro = false }) }
        .sheet(isPresented: $showInteractiveDemo) { 
            InteractiveDemoView(
                isPresented: $showInteractiveDemo,
                onOpenCamera: { showingCamera = true },
                onOpenCoach: { showingAIChat = true },
                onOpenFoodSearch: { showingAddFood = true },
                onOpenSettings: { showingSettings = true }
            )
        }
        .sheet(isPresented: $showingCoachPanel) {
            CoachPanelView()
        }
        .sheet(isPresented: $showingAutoTuneHistory) {
            AutoTuneHistoryView(records: AutoTuneEngine.shared.loadRecords())
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(capturedImage: .constant(nil), macroEntryStore: entryStore)
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualEntryView(entryStore: entryStore)
        }
        .sheet(isPresented: $showingAddFood) {
            #if DEBUG
            UnifiedFoodSearchView(macroEntryStore: entryStore, macroAIManager: ServiceFactory.createMockMacroAIManager())
            #else
            let manager = (try? ServiceFactory.createMacroAIManager()) ?? ServiceFactory.createMockMacroAIManager()
            UnifiedFoodSearchView(macroEntryStore: entryStore, macroAIManager: manager)
            #endif
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
            PaywallView()
        }
        .onChange(of: showPaywall) { _, newValue in
            if newValue {
                Analytics.paywallTriggered(source: "home", feature: "overlay")
            }
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
                }
                
                Spacer()
                
                // Streak indicator
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("\(dailyStreak)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow
                    .opacity(0.2))
                .cornerRadius(8)
                
                // Quick Auto‑Tune access
                Button(action: { showingAutoTuneHistory = true }) {
                    Image(systemName: "bolt.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                                                        )
                        .accessibilityLabel(Text("Auto‑Tune"))
                }

                // Upgrade button for Basic users
                if subscriptionManager.currentTier == .basic {
                    Button(action: { showPaywall = true; Analytics.paywallTriggered(source: "home", feature: "header_button") }) {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill").foregroundColor(.red).font(.caption)
                            Text("Upgrade").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.blue)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(8)
                    }
                }

                // Settings button
                Button(action: { showingSettings = true; Analytics.featureUse("settings", action: "open") }) {
                    Image(systemName: "gear")
                        .font(.title3)
                        .foregroundColor(themeManager.primaryColor)
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
        VStack(spacing: 10) { // tighten spacing slightly
            // Today's Calories with Fun Animation
            HStack {
                Text("Today's Calories:")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(entryStore.todaysTotals.calories)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryColor)
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
            
            // Free tier usage meters
            if !UserSubscriptionManager.shared.isPremium {
                HStack {
                    Text("Meals today: \(UserSubscriptionManager.shared.mealsLoggedToday)/2  •  Scans today: \(UserSubscriptionManager.shared.aiScansToday)/3")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
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
        VStack(spacing: 8) { // tighten spacing slightly
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
                            CoachEngine.shared.recordUserActionAndUpdateStreak()
                        Analytics.featureUse("camera", action: "open")
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
                            CoachEngine.shared.recordUserActionAndUpdateStreak()
                        Analytics.featureUse("manual_entry", action: "open")
                    },
                    effect: .typewriter
                )
            }
            
            // Food Search + Recipes side-by-side to reduce vertical height
            HStack(spacing: 12) {
                PlayfulButton(
                    title: "Food Search",
                    icon: "magnifyingglass",
                    color: .blue,
                    action: { 
                        showingAddFood = true
                        trackTierUsage()
                        updateStreak()
                        CoachEngine.shared.recordUserActionAndUpdateStreak()
                        Analytics.featureUse("food_search", action: "open")
                    },
                    effect: .magnify
                )

                PlayfulButton(
                    title: "Recipes",
                    icon: "book.fill",
                    color: .purple,
                    action: {
                        if isPremiumUser() {
                            showingRecipes = true
                            Analytics.featureUse("recipes", action: "open")
                        } else {
                            Analytics.premiumFeatureTapped("recipes")
                            Analytics.featurePaywallShown("recipes")
                            showPaywall = true
                        }
                    },
                    effect: .typewriter
                )
                
            }
            
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8) // Reduced from 10 to 8
    }
    
    // MARK: - Compact AI Assistant
    
    private var compactAIAssistant: some View {
        VStack(spacing: 12) {
            if notifDeniedAlert {
                HStack(spacing: 8) {
                    Image(systemName: "bell.slash.fill").foregroundColor(.orange)
                    Text("Enable notifications in Settings to get Coach nudges.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        notifDeniedAlert = false
                    }
                    .font(.caption)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            // Ask Coach button only (chat box removed)
            Button(action: {
                // Gate Coach for Basic unless within 7‑day trial (use SubscriptionManager)
                if subscriptionManager.currentTier == .basic && !CoachTrialManager.shared.isWithinTrialWindow() {
                    showPaywall = true
                    Analytics.featurePaywallShown("coach_locked")
                    return
                }
                if subscriptionManager.currentTier == .basic {
                    let started = CoachTrialManager.shared.startIfNeeded(days: 7)
                    if started { Analytics.featureUse("coach", action: "trial_started") }
                }
                showingAIChat = true
                updateStreak()
                CoachEngine.shared.recordUserActionAndUpdateStreak()
                Analytics.featureUse("chat", action: "open")
            }) {
                HStack {
                    Image(systemName: "message.fill")
                        .foregroundColor(.white)
                        .font(.title3)

                    Text("Ask Coach")
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
                .overlay(alignment: .topTrailing) {
                    // Coach badge (uses nudge count signal)
                    if badgeCount > 0 {
                        Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.red, in: Capsule())
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    // MARK: - Auto‑Tune Banner
    private func shouldShowAutoTuneBanner(_ rec: AutoTuneRecord) -> Bool {
        if let until = AutoTuneEngine.shared.getBannerDismissUntil(), until > Date() { return false }
        let days = Calendar.current.dateComponents([.day], from: rec.createdAt, to: Date()).day ?? 99
        return days < 7
    }
    
    @ViewBuilder
    private func autoTuneBanner(delta: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.circle.fill").foregroundColor(.yellow)
            Text("Auto‑Tune: calorie target \(delta >= 0 ? "+" : "")\(delta)% this week — View")
                .font(.caption)
                .foregroundColor(.primary)
                .onTapGesture { showingAutoTuneHistory = true }
            Spacer()
            Button("Dismiss") {
                AutoTuneEngine.shared.dismissBannerFor(days: 7)
            }
            .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Dock Actions
    private func handleDockAction(_ action: GlassDockView.DockAction) {
        print("[HomeView] Dock action: \(action)")
        switch action {
        case .coach: showingCoachPanel = true
        case .upgrade: showPaywall = true
        case .marketplace: showingMarketplace = true
        }
    }
    
    // MARK: - Demo Results Card
    
    private var demoResultsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Demo Results")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showDemoResults = false
                    UserDefaults.standard.removeObject(forKey: "ShowDemoResults")
                    UserDefaults.standard.removeObject(forKey: "DemoMacroEntry")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            
            if let foodName = demoMacroEntry["foodName"] as? String,
               let calories = demoMacroEntry["calories"] as? Int,
               let protein = demoMacroEntry["protein"] as? Double,
               let carbs = demoMacroEntry["carbs"] as? Double,
               let fat = demoMacroEntry["fat"] as? Double {
                
                VStack(spacing: 12) {
                    Text(foodName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(calories)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("Calories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(protein, specifier: "%.1f")g")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("Protein")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(carbs, specifier: "%.1f")g")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Carbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(fat, specifier: "%.1f")g")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            Text("Fat")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Text("This is how your food gets automatically added to your macros!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Supporting Functions
    
    private var badgeCount: Int {
        if UserDefaults.standard.bool(forKey: "coach_badge_override_zero") { return 0 }
        // Basic heuristic: show 1 if any coach-related notifications are scheduled
        // This is lightweight and avoids querying notification center each frame
        let keys = [
            "coach_last_sched_coach_daily_nudge",
            "coach_last_sched_coach_evening_nudge",
            "coach_last_sched_coach_weekly_summary",
            "coach_last_sched_coach_protein_by_lunch",
            "coach_last_sched_coach_prelog_dinner"
        ]
        let defaults = UserDefaults.standard
        let anyRecent = keys.contains { key in
            if let date = defaults.object(forKey: key) as? Date { return Date().timeIntervalSince(date) < 7*24*3600 }
            return false
        }
        return anyRecent ? 1 : 0
    }


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
    
    // MARK: - Helper Functions
    
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
            .scaleEffect(isPressed ? 0.98 : 1.0)
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


