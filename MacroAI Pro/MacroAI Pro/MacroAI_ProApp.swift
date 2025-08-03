//
//  MacroAIApp.swift
//  MacroAI
//
//  Main app entry point with original UI design

import SwiftUI
import SwiftData

@main
struct MacroAIApp: App {
    // Centralized ModelContainer to prevent data corruption
    let modelContainer: ModelContainer
    
    @StateObject private var premiumManager = PremiumManager()
    @StateObject private var storeKitManager = StoreKitManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var marketplaceManager = MarketplaceManager.shared
    @StateObject private var dietManager = DietManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isOnboardingComplete = false
    
    private var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "OnboardingSeen")
    }
    
    init() {
        do {
            // Create a single ModelContainer for the entire app
            let schema = Schema([
                MacroEntry.self,
                Recipe.self,
                NutritionCacheEntry.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Set up the cleanup task with the centralized container
            NutritionCacheCleanupTask.shared.setModelContainer(modelContainer)
            
            print("✅ [MacroAIApp] Centralized ModelContainer initialized successfully")
        } catch {
            fatalError("❌ [MacroAIApp] Failed to initialize ModelContainer: \(error)")
        }
    }
    @State private var showPaywall = false
    @AppStorage("selectedTheme") private var selectedTheme: String = "System"
    
    // Convert selectedTheme to ColorScheme
    private var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "Light":
            return .light
        case "Dark":
            return .dark
        case "System":
            return nil
        default:
            return nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !hasSeenOnboarding || !isOnboardingComplete {
                    // Show onboarding for new users
                    OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                        .modelContainer(modelContainer)
                        .environmentObject(premiumManager)
                        .environmentObject(storeKitManager)
                        .environmentObject(themeManager)
                        .environmentObject(marketplaceManager)
                        .environmentObject(dietManager)
                        .environmentObject(subscriptionManager)
                        .preferredColorScheme(colorScheme)
                } else {
                    // Main app content - Show after onboarding
                    HomeView()
                        .modelContainer(modelContainer) // Use centralized ModelContainer
                        .environmentObject(premiumManager)
                        .environmentObject(storeKitManager)
                        .environmentObject(themeManager)
                        .environmentObject(marketplaceManager)
                        .environmentObject(dietManager)
                        .environmentObject(subscriptionManager)
                        .preferredColorScheme(colorScheme) // Apply the selected color scheme
                        .onAppear {
                            checkPaywallStatus()
                            // Initialize API keys
                            SecureConfig.initializeAPIKeys()
                            // Setup production API keys
                            setupAPIKeys()
                        }
                }
            }
            .onAppear {
                // Update onboarding state when app starts
                isOnboardingComplete = hasSeenOnboarding
                print("🔄 [MacroAIApp] Onboarding state: UserDefaults=\(hasSeenOnboarding), isOnboardingComplete=\(isOnboardingComplete)")
            }
            .onChange(of: isOnboardingComplete) { _, newValue in
                print("🔄 [MacroAIApp] isOnboardingComplete changed to: \(newValue)")
            }
            
            // Paywall overlay (only shown when explicitly triggered)
            if showPaywall {
                AnnoyingPaywallView(isPresented: $showPaywall)
                    .modelContainer(modelContainer) // Use centralized ModelContainer
                    .environmentObject(premiumManager)
                    .environmentObject(storeKitManager)
                    .environmentObject(themeManager)
                    .environmentObject(marketplaceManager)
                    .environmentObject(dietManager)
                    .environmentObject(subscriptionManager)
                    .preferredColorScheme(colorScheme) // Apply the selected color scheme
            }
        }
    }
    
    private func checkPaywallStatus() {
        // Don't show paywall on first app open
        // Paywall will be triggered after user has used the app (e.g., after completing a search)
        // This is handled in HomeView and other usage points
    }
    
    // MARK: - API Key Setup (Production Ready)
    
    private func setupAPIKeys() {
        // Production API key setup - only set if not already in keychain
        
        // Check if API keys are already configured
        let hasOpenAI = SecureConfig.getOpenAIAPIKey() != nil
        let hasSpoonacular = SecureConfig.getSpoonacularAPIKey() != nil
        
        // Only set keys if they don't exist (prevents overwriting user-set keys)
        if !hasOpenAI {
            // TODO: Replace with your actual OpenAI API key for production
            // ServiceFactory.saveOpenAIKey("sk-proj-your-actual-openai-key-here")
            print("⚠️ [MacroAIApp] OpenAI API key not configured - AI features will use mock responses")
        } else {
            print("✅ [MacroAIApp] OpenAI API key configured")
        }
        
        if !hasSpoonacular {
            // TODO: Replace with your actual Spoonacular API key for production
            // ServiceFactory.saveSpoonacularKey("your-actual-spoonacular-key-here")
            print("⚠️ [MacroAIApp] Spoonacular API key not configured - nutrition service will use mock responses")
        } else {
            print("✅ [MacroAIApp] Spoonacular API key configured")
        }
        
        // For production release, uncomment and add your actual API keys:
        /*
        if !hasOpenAI {
            ServiceFactory.saveOpenAIKey("sk-proj-your-actual-openai-key-here")
        }
        if !hasSpoonacular {
            ServiceFactory.saveSpoonacularKey("your-actual-spoonacular-key-here")
        }
        */
    }


// HomeView is now in a separate file: HomeView.swift

}
