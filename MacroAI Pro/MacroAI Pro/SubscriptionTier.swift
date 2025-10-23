//  SubscriptionTier.swift
//  MacroAI
//
//  Subscription tiers and AI credit system for monetization

import Foundation
import StoreKit
import Combine

enum SubscriptionTier: String, CaseIterable {
    case basic = "basic"
    case pro = "pro" 
    case elite = "elite"
    
    var displayName: String {
        switch self {
        case .basic: return "Macro AI Basic"
        case .pro: return "Macro AI Pro"
        case .elite: return "Macro AI Elite"
        }
    }
    
    var features: [String] {
        switch self {
        case .basic:
            return [
                "Manual macro entry",
                "HealthKit sync", 
                "Full macro history",
                "Basic nutrition data",
                "5 AI food scans per hour (max 10/day)"
            ]
        case .pro:
            return [
                "Everything in Basic",
                "Unlimited AI food scanning",
                "Unlimited AI chat assistant",
                "Diet suggestion wizard",
                "Visual entry tracking"
            ]
        case .elite:
            return [
                "Everything in Pro",
                "Unlimited AI chat assistant",
                "Advanced nutrient analysis", 
                "Weekly diet optimization reports",
                "Priority support"
            ]
        }
    }
    
    var monthlyPrice: String {
        switch self {
        case .basic: return "Free"
        case .pro: return "$4.99"
        case .elite: return "$5.99"
        }
    }
    
    var yearlyPrice: String {
        switch self {
        case .basic: return "Free"
        case .pro: return "$39.99"
        case .elite: return "$59.99"
        }
    }
    
    var productID: String {
        switch self {
        case .basic: return ""
        case .pro: return "pro_yearly"
        case .elite: return "elite_yearly"
        }
    }
    
    var monthlyProductID: String {
        switch self {
        case .basic: return ""
        case .pro: return "pro_monthly"
        case .elite: return "elite_monthly"
        }
    }
    
    // Camera scanning limits (separate from chat)
    var dailyCameraScanLimit: Int {
        switch self {
        case .basic: return 10  // 10 scans per day for free
        case .pro, .elite: return Int.max // Unlimited for paid
        }
    }
    
    var hourlyCameraScanLimit: Int {
        switch self {
        case .basic: return 5   // 5 scans per hour for free
        case .pro, .elite: return Int.max // Unlimited for paid
        }
    }
    
    // Chat AI limits (separate from camera)
    var monthlyChatLimit: Int {
        switch self {
        case .basic: return 0   // Chat locked for free users
        case .pro: return Int.max // Unlimited chat for paid tiers
        case .elite: return Int.max // Unlimited chat
        }
    }
    
    // Feature access
    var hasCameraScanning: Bool {
        return true // All tiers get camera scanning (with limits)
    }
    
    var hasChatAccess: Bool {
        switch self {
        case .basic: return false // Chat locked for free
        case .pro, .elite: return true
        }
    }
    
    var hasDietWizard: Bool {
        switch self {
        case .basic: return false
        case .pro, .elite: return true
        }
    }
    
    var hasAdvancedAnalytics: Bool {
        switch self {
        case .basic, .pro: return false
        case .elite: return true
        }
    }
    
    var hasUnlimitedAI: Bool {
        switch self {
        case .basic, .pro: return false
        case .elite: return true
        }
    }
}

// MARK: - AI Credit Pack System

struct AICreditPack {
    static let standardPack = AICreditPack(
        productID: "ai_credits_10",
        credits: 10,
        price: "$4.99",
        displayName: "10 AI Credits"
    )
    
    let productID: String
    let credits: Int
    let price: String
    let displayName: String
}

// MARK: - Subscription Manager

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var currentTier: SubscriptionTier = .basic
    @Published var aiCredits: Int = 0
    @Published var dailyCameraUsage: Int = 0
    @Published var hourlyCameraUsage: Int = 0
    @Published var monthlyChatUsage: Int = 0
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: Set<String> = []
    @Published var isLoadingProducts: Bool = false
    @Published var productLoadError: String? = nil
    
    // Trial management
    @Published var isTrialActive: Bool = false
    @Published var trialDaysRemaining: Int = 0
    

    
    private let productIDs: Set<String> = [
        "pro_yearly",
        "pro_monthly", 
        "elite_yearly",
        "elite_monthly",
        "ai_credits_10"
    ]
    
    private init() {
        // Initialize asynchronously to avoid blocking app startup
        Task(priority: .background) {
            await loadProducts()
            await checkSubscriptionStatus()
            loadUsageData()
            // Listen for transaction updates to handle delayed deliveries (e.g., consumables)
            Task.detached { [weak self] in
                guard let self = self else { return }
                for await update in Transaction.updates {
                    do {
                        let transaction = try self.checkVerified(update)
                        await MainActor.run {
                            if transaction.productID == AICreditPack.standardPack.productID {
                                self.aiCredits += AICreditPack.standardPack.credits
                                self.saveUsageData()
                                print("🔢 [SubscriptionManager] Credited \(AICreditPack.standardPack.credits) AI credits from updates. New balance: \(self.aiCredits)")
                            }
                        }
                        await transaction.finish()
                    } catch {
                        print("❌ [SubscriptionManager] Failed to verify transaction update: \(error)")
                    }
                }
            }
        }
    }

    #if DEBUG
    // DEBUG-only override to force premium access for testing
    func forcePremiumOverride(_ enabled: Bool) {
        if enabled {
            currentTier = .elite
        } else {
            // revert to basic for safety; testers can restore purchases to return
            currentTier = .basic
        }
    }
    #endif
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        await MainActor.run {
            self.isLoadingProducts = true
            self.productLoadError = nil
        }
        do {
            let products = try await Product.products(for: productIDs)
            await MainActor.run {
                self.products = products
                self.isLoadingProducts = false
                print("🛒 [SubscriptionManager] Loaded products: \(products.map { $0.id }.joined(separator: ", "))")
            }
        } catch {
            print("Failed to load products: \(error)")
            await MainActor.run {
                self.isLoadingProducts = false
                self.productLoadError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Subscription Status
    
    // Marked nonisolated so it can be called from background tasks (e.g., Task.detached)
    nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    func checkSubscriptionStatus() async {
        // Check for sandbox vs production environment
        let isSandbox = AppEnvironment.isSandbox
        print("🔍 [SubscriptionManager] Environment: \(isSandbox ? "Sandbox" : "Production") (build=\(AppEnvironment.isSandboxBuild), receiptSandbox=\(AppEnvironment.isSandboxReceipt))")
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                await MainActor.run {
                    if transaction.productID.contains("elite") {
                        self.currentTier = .elite
                        self.purchasedSubscriptions.insert(transaction.productID)
                    } else if transaction.productID.contains("pro") {
                        self.currentTier = .pro
                        self.purchasedSubscriptions.insert(transaction.productID)
                    }
                }
                
                print("✅ [SubscriptionManager] Verified transaction: \(transaction.productID)")
            } catch {
                print("❌ [SubscriptionManager] Failed to verify transaction: \(error)")
                
                // Handle sandbox receipt in production scenario
                if !isSandbox {
                    print("⚠️ [SubscriptionManager] Production app with sandbox receipt - this is expected during testing")
                }
            }
        }
    }
    
    // MARK: - Purchase Methods
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // Activate trial for any successful purchase
            print("🎁 [SubscriptionManager] Purchase successful for product: \(product.id)")
            await MainActor.run {
                activateTrial(for: product)
                // Top-up AI credits for credit pack purchases
                if product.id == AICreditPack.standardPack.productID {
                    aiCredits += AICreditPack.standardPack.credits
                    saveUsageData()
                    print("🔢 [SubscriptionManager] Credited \(AICreditPack.standardPack.credits) AI credits. New balance: \(aiCredits)")
                }
            }
            
            await transaction.finish()
            await checkSubscriptionStatus()
            print("🧾 [SubscriptionManager] Finished transaction and refreshed status")
            
        case .userCancelled:
            print("❌ [SubscriptionManager] Purchase cancelled by user")
            throw StoreError.userCancelled
            
        case .pending:
            print("⏳ [SubscriptionManager] Purchase pending approval")
            throw StoreError.pending
            
        @unknown default:
            print("❌ [SubscriptionManager] Unknown purchase result")
            throw StoreError.failedVerification
        }
    }
    
    // MARK: - Trial Management
    
    private func activateTrial(for product: Product) {
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: "TrialStartDate")
        defaults.set(true, forKey: "IsPremiumTrial")
        
        // Set trial tier based on product ID
        if product.id.contains("elite") {
            currentTier = .elite
        } else if product.id.contains("pro") {
            currentTier = .pro
        } else {
            currentTier = .basic
        }
        
        print("🎁 [SubscriptionManager] Trial activated for tier: \(currentTier.displayName)")
    }
    
    // MARK: - Camera Scanning Usage
    
    func canMakeCameraScan() -> Bool {
        // Check daily and hourly limits
        return dailyCameraUsage < currentTier.dailyCameraScanLimit && 
               hourlyCameraUsage < currentTier.hourlyCameraScanLimit
    }
    
    func recordCameraScan() {
        dailyCameraUsage += 1
        hourlyCameraUsage += 1
        
        saveUsageData()
    }
    
    func getRemainingCameraScans() -> String {
        switch currentTier {
        case .basic:
            let dailyRemaining = max(0, currentTier.dailyCameraScanLimit - dailyCameraUsage)
            let hourlyRemaining = max(0, currentTier.hourlyCameraScanLimit - hourlyCameraUsage)
            return "\(min(dailyRemaining, hourlyRemaining)) scans available"
        case .pro, .elite:
            return "Unlimited"
        }
    }
    
    // MARK: - Chat AI Usage
    
    func canMakeChatRequest() -> Bool {
        // Chat is available only for paid tiers; unlimited when available
        return currentTier.hasChatAccess
    }
    
    func recordChatRequest() {
        // No token charge for chat; unlimited for paid tiers.
        // Keep usage data unchanged to avoid gating.
    }
    
    func getRemainingChatRequests() -> String {
        if currentTier.hasChatAccess {
            return "Unlimited"
        } else {
            return "Chat locked - upgrade to unlock"
        }
    }

    // MARK: - Scan Credits (for free tier over daily limit)
    func consumeScanCreditIfAvailable() -> Bool {
        if aiCredits > 0 {
            aiCredits -= 1
            saveUsageData()
            return true
        }
        return false
    }
    
    private func loadUsageData() {
        let userDefaults = UserDefaults.standard
        dailyCameraUsage = userDefaults.integer(forKey: "dailyCameraUsage")
        hourlyCameraUsage = userDefaults.integer(forKey: "hourlyCameraUsage")
        monthlyChatUsage = userDefaults.integer(forKey: "monthlyChatUsage")
        aiCredits = userDefaults.integer(forKey: "aiCredits")
        
        // Reset daily camera usage if needed
        let lastDailyReset = userDefaults.object(forKey: "lastDailyReset") as? Date ?? Date.distantPast
        if !Calendar.current.isDate(lastDailyReset, inSameDayAs: Date()) {
            dailyCameraUsage = 0
            userDefaults.set(Date(), forKey: "lastDailyReset")
        }
        
        // Reset hourly camera usage if needed
        let lastHourlyReset = userDefaults.object(forKey: "lastHourlyReset") as? Date ?? Date.distantPast
        if !Calendar.current.isDate(lastHourlyReset, equalTo: Date(), toGranularity: .hour) {
            hourlyCameraUsage = 0
            userDefaults.set(Date(), forKey: "lastHourlyReset")
        }
        
        // Reset monthly chat usage if needed
        let lastMonthlyReset = userDefaults.object(forKey: "lastMonthlyChatReset") as? Date ?? Date.distantPast
        if Calendar.current.dateInterval(of: .month, for: Date()) != 
           Calendar.current.dateInterval(of: .month, for: lastMonthlyReset) {
            monthlyChatUsage = 0
            userDefaults.set(Date(), forKey: "lastMonthlyChatReset")
        }
    }
    
    private func saveUsageData() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(dailyCameraUsage, forKey: "dailyCameraUsage")
        userDefaults.set(hourlyCameraUsage, forKey: "hourlyCameraUsage")
        userDefaults.set(monthlyChatUsage, forKey: "monthlyChatUsage")
        userDefaults.set(aiCredits, forKey: "aiCredits")
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        // Use StoreKit directly to restore purchases
        try await AppStore.sync()
        
        // Refresh subscription status after restore
        await checkSubscriptionStatus()
        
        print("✅ [SubscriptionManager] Purchases restored successfully")
    }
    
    // MARK: - Reset to Defaults
    
    func resetToDefaults() {
        // Reset to basic tier
        currentTier = .basic
        
        // Clear usage data
        dailyCameraUsage = 0
        hourlyCameraUsage = 0
        monthlyChatUsage = 0
        aiCredits = 0
        
        // Clear UserDefaults for subscription-related data
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "dailyCameraUsage")
        userDefaults.removeObject(forKey: "hourlyCameraUsage")
        userDefaults.removeObject(forKey: "monthlyChatUsage")
        userDefaults.removeObject(forKey: "aiCredits")
        userDefaults.removeObject(forKey: "lastDailyReset")
        userDefaults.removeObject(forKey: "lastHourlyReset")
        userDefaults.removeObject(forKey: "lastMonthlyChatReset")
        
        print("✅ [SubscriptionManager] Reset to defaults")
    }
}

enum StoreError: Error, LocalizedError {
    case failedVerification
    case userCancelled
    case pending
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed. Please try again."
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending approval."
        }
    }
} 
