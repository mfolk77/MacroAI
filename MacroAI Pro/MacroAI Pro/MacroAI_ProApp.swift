//
//  MacroAIApp.swift
//  MacroAI
//
//  Main app entry point with original UI design

import SwiftUI
import SwiftData
import Foundation
import UserNotifications

@main
struct MacroAIApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    // Centralized ModelContainer to prevent data corruption
    let modelContainer: ModelContainer
    
    @StateObject private var premiumManager = PremiumManager()
    @StateObject private var storeKitManager = StoreKitManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var marketplaceManager = MarketplaceManager.shared
    @StateObject private var dietManager = DietManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var updateManager = AppUpdateManager()
    @State private var isOnboardingComplete = false
    
    private var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "OnboardingSeen")
    }
    
    init() {
        // Register custom value transformers for SwiftData
        ValueTransformer.setValueTransformer(StringArrayTransformer(), forName: NSValueTransformerName("StringArrayTransformer"))
        
        do {
            // Create a single ModelContainer for the entire app
            let schema = Schema([
                MacroEntry.self as any PersistentModel.Type,
                Recipe.self as any PersistentModel.Type,
                NutritionCacheEntry.self as any PersistentModel.Type,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Set up the cleanup task with the centralized container
            NutritionCacheCleanupTask.shared.setModelContainer(modelContainer)
            
            print("✅ [MacroAIApp] Centralized ModelContainer initialized successfully")
        } catch {
            // Fall back to in-memory ModelContainer to avoid crash
            print("⚠️ [MacroAIApp] Failed to initialize persistent ModelContainer: \(error). Falling back to in-memory store.")
            let fallbackSchema = Schema([
                MacroEntry.self as any PersistentModel.Type,
                Recipe.self as any PersistentModel.Type,
                NutritionCacheEntry.self as any PersistentModel.Type,
            ])
            let inMemoryConfig = ModelConfiguration(schema: fallbackSchema, isStoredInMemoryOnly: true)
            if let inMemoryContainer = try? ModelContainer(for: fallbackSchema, configurations: [inMemoryConfig]) {
                modelContainer = inMemoryContainer
            } else if let minimalContainer = try? ModelContainer(for: MacroEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) {
                modelContainer = minimalContainer
            } else {
                // Last resort: force-create a minimal in-memory container
                modelContainer = try! ModelContainer(for: MacroEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            }
        }
        // Ensure local notifications show while app is in foreground
        UNUserNotificationCenter.current().delegate = AppNotificationDelegate.shared
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
                
                // Paywall overlay removed to prevent double-presentation; using sheet below
            }
            // Show paywall overlay when flagged
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .modelContainer(modelContainer)
                    .environmentObject(premiumManager)
                    .environmentObject(storeKitManager)
                    .environmentObject(themeManager)
                    .environmentObject(marketplaceManager)
                    .environmentObject(dietManager)
                    .environmentObject(subscriptionManager)
                    .preferredColorScheme(colorScheme)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPaywallDueToDailyLimit"))) { _ in
                showPaywall = true
            }
            .onAppear {
                Analytics.lifecycle("launch")
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    Analytics.lifecycle("foreground")
                    updateManager.checkForUpdate()
                case .inactive:
                    Analytics.lifecycle("inactive")
                case .background:
                    Analytics.lifecycle("background")
                @unknown default:
                    break
                }
            }
            .onAppear {
                // Check for updates on app launch
                updateManager.checkForUpdate()
            }
            .onAppear {
                // Update onboarding state when app starts
                isOnboardingComplete = hasSeenOnboarding
                print("🔄 [MacroAIApp] Onboarding state: UserDefaults=\(hasSeenOnboarding), isOnboardingComplete=\(isOnboardingComplete)")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPaywallDueToScanLimit"))) { _ in
                showPaywall = true
            }
            .onChange(of: isOnboardingComplete) { _, newValue in
                print("🔄 [MacroAIApp] isOnboardingComplete changed to: \(newValue)")
            }
            .alert(
                "Update Available",
                isPresented: Binding(
                    get: { updateManager.updateAvailable },
                    set: { updateManager.updateAvailable = $0 }
                )
            ) {
                Button("Later", role: .cancel) {
                    updateManager.updateAvailable = false
                }
                Button("Update") {
                    if let url = updateManager.appStoreURL {
                        openURL(url)
                    }
                    updateManager.updateAvailable = false
                }
            } message: {
                Text("A newer version (\(updateManager.latestVersion ?? "")) is available. Please update for the latest fixes.")
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

// MARK: - Notification Delegate to present alerts in foreground
final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AppNotificationDelegate()
    private override init() { super.init() }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner/sound even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
