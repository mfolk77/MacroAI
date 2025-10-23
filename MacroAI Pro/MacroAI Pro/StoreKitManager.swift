// StoreKitManager.swift
// In-app purchase and premium subscription management

import Foundation
import StoreKit
import Combine

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var isPremium = false
    @Published var isTrialActive = false
    @Published var daysRemainingInTrial = 0
    
    private let subscriptionManager = SubscriptionManager.shared
    
    init() {
        // Initialize with real StoreKit integration
        print("💰 [StoreKitManager] Initializing with real StoreKit integration")
        checkEnvironment()
        
        // Check initial subscription status
        Task {
            await checkPremiumStatus()
        }
    }
    
    // MARK: - Premium Management
    
    func checkPremiumStatus() async {
        await subscriptionManager.checkSubscriptionStatus()
        
        // Update local state based on subscription manager
        isPremium = subscriptionManager.currentTier != .basic
        isTrialActive = subscriptionManager.isTrialActive
        daysRemainingInTrial = subscriptionManager.trialDaysRemaining
        
        print("💰 [StoreKitManager] Premium status updated: \(isPremium)")
    }
    
    func purchasePremium() async throws {
        // Find the Pro subscription product
        guard let proProduct = subscriptionManager.products.first(where: { $0.id.contains("pro") }) else {
            throw StoreError.failedVerification
        }
        
        try await subscriptionManager.purchase(proProduct)
        await checkPremiumStatus()
    }
    
    func restorePurchases() async throws {
        try await subscriptionManager.restorePurchases()
        await checkPremiumStatus()
    }
    
    // MARK: - Trial Management
    
    func startTrial() {
        // Trial is handled by SubscriptionManager
        print("🎁 [StoreKitManager] Trial management delegated to SubscriptionManager")
    }
    
    func endTrial() {
        // Trial is handled by SubscriptionManager
        print("⏰ [StoreKitManager] Trial management delegated to SubscriptionManager")
    }
    
    // MARK: - Environment Detection
    
    private func checkEnvironment() {
        // Log environment for debugging
        #if DEBUG
        print("🔍 [StoreKitManager] Running in DEBUG mode")
        #else
        print("🚀 [StoreKitManager] Running in RELEASE mode")
        #endif
        
        // Check if running in simulator
        #if targetEnvironment(simulator)
        print("📱 [StoreKitManager] Running in iOS Simulator")
        #else
        print("📱 [StoreKitManager] Running on physical device")
        #endif
    }
} 
