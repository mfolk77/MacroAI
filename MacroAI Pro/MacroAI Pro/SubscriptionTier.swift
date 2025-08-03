//  SubscriptionTier.swift
//  MacroAI
//
//  Subscription tiers and AI credit system for monetization

import Foundation
import StoreKit
internal import Combine

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
                "AI chat assistant (15/month)",
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
        case .pro: return "com.FolkTechAI.MacroAI.pro.yearly"
        case .elite: return "com.FolkTechAI.MacroAI.elite.yearly"
        }
    }
    
    var monthlyProductID: String {
        switch self {
        case .basic: return ""
        case .pro: return "com.FolkTechAI.MacroAI.pro.monthly"
        case .elite: return "com.FolkTechAI.MacroAI.elite.monthly"
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
        case .pro: return 15    // 15 chat requests per month
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
        productID: "com.FolkTechAI.MacroAI.credits.10",
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
    
    // TestFlight bypass
    var isTestFlightUser: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "isTestFlightUser")
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }
    
    private let productIDs: Set<String> = [
        "com.FolkTechAI.MacroAI.pro.yearly",
        "com.FolkTechAI.MacroAI.pro.monthly", 
        "com.FolkTechAI.MacroAI.elite.yearly",
        "com.FolkTechAI.MacroAI.elite.monthly",
        "com.FolkTechAI.MacroAI.credits.10"
    ]
    
    private init() {
        // Initialize asynchronously to avoid blocking app startup
        Task(priority: .background) {
            await loadProducts()
            await checkSubscriptionStatus()
            loadUsageData()
        }
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: productIDs)
            await MainActor.run {
                self.products = products
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Subscription Status
    
    func checkSubscriptionStatus() async {
        // TestFlight users get Elite access
        if isTestFlightUser {
            await MainActor.run {
                self.currentTier = .elite
            }
            return
        }
        
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
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
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
            }
            
            await transaction.finish()
            await checkSubscriptionStatus()
            
        case .userCancelled, .pending:
            break
        @unknown default:
            break
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
        // TestFlight users have unlimited access
        if isTestFlightUser {
            return true
        }
        
        // Check daily and hourly limits
        return dailyCameraUsage < currentTier.dailyCameraScanLimit && 
               hourlyCameraUsage < currentTier.hourlyCameraScanLimit
    }
    
    func recordCameraScan() {
        guard !isTestFlightUser else { return }
        
        dailyCameraUsage += 1
        hourlyCameraUsage += 1
        
        saveUsageData()
    }
    
    func getRemainingCameraScans() -> String {
        if isTestFlightUser {
            return "Unlimited (TestFlight)"
        }
        
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
        // TestFlight users have unlimited access
        if isTestFlightUser {
            return true
        }
        
        // Check if tier has chat access
        guard currentTier.hasChatAccess else {
            return false
        }
        
        // Check monthly limits
        return monthlyChatUsage < currentTier.monthlyChatLimit
    }
    
    func recordChatRequest() {
        guard !isTestFlightUser else { return }
        
        monthlyChatUsage += 1
        saveUsageData()
    }
    
    func getRemainingChatRequests() -> String {
        if isTestFlightUser {
            return "Unlimited (TestFlight)"
        }
        
        guard currentTier.hasChatAccess else {
            return "Chat locked - upgrade to unlock"
        }
        
        switch currentTier {
        case .basic:
            return "Chat locked - upgrade to unlock"
        case .pro:
            let remaining = max(0, currentTier.monthlyChatLimit - monthlyChatUsage)
            return "\(remaining) this month"
        case .elite:
            return "Unlimited"
        }
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
}

enum StoreError: Error {
    case failedVerification
} 