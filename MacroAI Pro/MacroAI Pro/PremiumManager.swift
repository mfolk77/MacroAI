//
//  PremiumManager.swift
//  MacroAI
//
//  Manages premium features and trial logic

import Foundation
import SwiftUI
internal import Combine

class PremiumManager: ObservableObject {
    @Published var isPremium = false
    @Published var isTrialActive = false
    @Published var daysRemainingInTrial = 7
    @Published var shouldShowPaywall = false
    @Published var currentTier: SubscriptionTier = .basic
    
    private let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days in seconds
    
    enum SubscriptionTier: String, CaseIterable {
        case basic = "Basic"
        case pro = "Pro"
        case elite = "Elite"
        
        var displayName: String {
            switch self {
            case .basic: return "Basic (Free)"
            case .pro: return "Pro"
            case .elite: return "Elite"
            }
        }
    }
    
    init() {
        checkPremiumStatus()
    }
    
    func checkPremiumStatus() {
        let defaults = UserDefaults.standard
        
        // Check current subscription tier
        if let tierString = defaults.string(forKey: "CurrentSubscriptionTier"),
           let tier = SubscriptionTier(rawValue: tierString) {
            currentTier = tier
            
            // Set premium status based on tier
            isPremium = (tier == .pro || tier == .elite)
            
            // Check if trial is active
            if let trialStartDate = defaults.object(forKey: "TrialStartDate") as? Date {
                let trialEndDate = trialStartDate.addingTimeInterval(trialDuration)
                let now = Date()
                
                if now < trialEndDate {
                    // Trial is still active
                    isTrialActive = true
                    let remainingTime = trialEndDate.timeIntervalSince(now)
                    daysRemainingInTrial = Int(ceil(remainingTime / (24 * 60 * 60)))
                } else {
                    // Trial has expired
                    isTrialActive = false
                    // User stays on their current tier
                }
            } else {
                isTrialActive = false
            }
        } else {
            // Default to basic tier
            currentTier = .basic
            isPremium = false
            isTrialActive = false
        }
    }
    
    func activateTrial() {
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: "TrialStartDate")
        defaults.set(true, forKey: "IsPremiumTrial")
        
        isTrialActive = true
        daysRemainingInTrial = 7
        
        // Schedule check for trial expiration
        scheduleTrialExpirationCheck()
    }
    
    func upgradeToTier(_ tier: SubscriptionTier) {
        let defaults = UserDefaults.standard
        defaults.set(tier.rawValue, forKey: "CurrentSubscriptionTier")
        
        currentTier = tier
        isPremium = (tier == .pro || tier == .elite)
        shouldShowPaywall = false
    }
    
    func purchasePremium() {
        upgradeToTier(.pro)
    }
    
    private func scheduleTrialExpirationCheck() {
        // Check every hour for trial expiration
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            DispatchQueue.main.async {
                self.checkPremiumStatus()
            }
        }
    }
    
    // Feature access methods for 3-tier system
    func canUseBarcodeScanning() -> Bool {
        // Basic: Limited barcode scanning (5 scans per day)
        // Pro/Elite: Unlimited barcode scanning
        return true // All tiers can use barcode scanning
    }
    
    func canUseAdvancedAI() -> Bool {
        // Basic: Basic AI features
        // Pro/Elite: Advanced AI with detailed analysis
        return true // All tiers can use AI features
    }
    
    func canUseDetailedAnalytics() -> Bool {
        // Basic: Basic analytics
        // Pro/Elite: Detailed analytics and insights
        return currentTier == .pro || currentTier == .elite
    }
    
    func canSaveUnlimitedRecipes() -> Bool {
        // Basic: Limited recipes (3 recipes)
        // Pro/Elite: Unlimited recipes
        return currentTier == .pro || currentTier == .elite
    }
    
    func canAccessPremiumThemes() -> Bool {
        // Basic: Basic themes only
        // Pro/Elite: All premium themes
        return currentTier == .pro || currentTier == .elite
    }
    
    func canUseEliteFeatures() -> Bool {
        // Elite-only features
        return currentTier == .elite
    }
    
    // Tier limits
    func getTierLimits() -> (barcodeScansRemaining: Int, recipesRemaining: Int) {
        let defaults = UserDefaults.standard
        let scansUsed = defaults.integer(forKey: "BarcodeScansUsed")
        let recipesUsed = defaults.integer(forKey: "RecipesUsed")
        
        switch currentTier {
        case .basic:
            return (max(0, 5 - scansUsed), max(0, 3 - recipesUsed))
        case .pro, .elite:
            return (999, 999) // Unlimited
        }
    }
    
    // Trial info
    func getTrialInfo() -> (isActive: Bool, daysRemaining: Int) {
        return (isTrialActive, daysRemainingInTrial)
    }
} 