//  PaywallView.swift
//  MacroAI
//
//  Tiered subscription paywall with Pro and Elite options

import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: SubscriptionTier = .pro
    @State private var isYearly = true
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    tierSelectionSection
                    pricingToggle
                    trialInfoSection
                    selectedTierDetails
                    purchaseButton
                    aiCreditSection
                    
                    if subscriptionManager.isTestFlightUser {
                        testFlightBanner
                    }
                }
                .padding()
            }
            .navigationTitle("Upgrade MacroAI")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.macro")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)
            
            Text("Unlock AI-Powered Nutrition")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Text("Transform your nutrition tracking with intelligent food scanning and personalized AI insights")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var tierSelectionSection: some View {
        VStack(spacing: 12) {
            HStack {
                tierCard(.pro)
                tierCard(.elite)
            }
        }
    }
    
    private func tierCard(_ tier: SubscriptionTier) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.displayName)
                        .font(.headline)
                        .foregroundColor(selectedTier == tier ? .white : .primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("7-Day Free Trial")
                            .font(.caption)
                            .foregroundColor(selectedTier == tier ? .white.opacity(0.8) : .green)
                        
                        Text(isYearly ? tier.yearlyPrice : tier.monthlyPrice)
                            .font(.title2.bold())
                            .foregroundColor(selectedTier == tier ? .white : .blue)
                    }
                }
                
                Spacer()
                
                if tier == .pro {
                    Text("POPULAR")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(tier.features.prefix(3), id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(selectedTier == tier ? .white : .green)
                            .font(.caption)
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(selectedTier == tier ? .white.opacity(0.9) : .secondary)
                    }
                }
                
                if tier.features.count > 3 {
                    Text("+ \(tier.features.count - 3) more features")
                        .font(.caption)
                        .foregroundColor(selectedTier == tier ? .white.opacity(0.7) : .secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(selectedTier == tier ? Color.blue : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(selectedTier == tier ? .blue : .clear, lineWidth: 2)
        )
        .onTapGesture {
            selectedTier = tier
        }
    }
    
    private var trialInfoSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(.green)
                Text("7-Day Free Trial")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
            }
            
            Text("Try all premium features free for 7 days. Cancel anytime during the trial period.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var pricingToggle: some View {
        HStack {
            Button(action: { isYearly = false }) {
                Text("Monthly")
                    .fontWeight(isYearly ? .regular : .semibold)
                    .foregroundColor(isYearly ? .secondary : .blue)
            }
            
            Spacer()
            
            VStack {
                Text("Save 33%")
                    .font(.callout.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.orange.gradient)
                            .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                Text("with Yearly")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .opacity(isYearly ? 1 : 0.5)
            
            Spacer()
            
            Button(action: { isYearly = true }) {
                Text("Yearly")
                    .fontWeight(isYearly ? .semibold : .regular)
                    .foregroundColor(isYearly ? .blue : .secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var selectedTierDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's included:")
                .font(.headline)
            
            ForEach(selectedTier.features, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(feature)
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var purchaseButton: some View {
        Button(action: purchase) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Start 7-Day Free Trial")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue.gradient)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isPurchasing)
    }
    
    private var aiCreditSection: some View {
        VStack(spacing: 12) {
            Divider()
            
            Text("Or buy AI credits as needed")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: purchaseCredits) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("10 AI Credits")
                            .font(.headline)
                        Text("Perfect for occasional use")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$4.99")
                        .font(.title3.bold())
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var testFlightBanner: some View {
        VStack {
            Text("🧪 TestFlight User")
                .font(.headline)
            Text("You have unlimited access to all features during testing")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Purchase Actions
    
    private func purchase() {
        Task {
            isPurchasing = true
            
            do {
                let productID = isYearly ? selectedTier.productID : selectedTier.monthlyProductID
                guard let product = subscriptionManager.products.first(where: { $0.id == productID }) else {
                    throw StoreError.failedVerification
                }
                
                try await subscriptionManager.purchase(product)
                dismiss()
                
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            isPurchasing = false
        }
    }
    
    private func purchaseCredits() {
        Task {
            do {
                guard let product = subscriptionManager.products.first(where: { $0.id == AICreditPack.standardPack.productID }) else {
                    throw StoreError.failedVerification
                }
                
                try await subscriptionManager.purchase(product)
                dismiss()
                
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Feature Upgrade Prompt

struct FeatureUpgradePrompt: View {
    let feature: String
    let requiredTier: SubscriptionTier
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue.gradient)
            
            Text("Upgrade to \(requiredTier.displayName)")
                .font(.title2.bold())
            
            Text("To use \(feature), upgrade to unlock this premium feature and many more.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("See Upgrade Options") {
                showingPaywall = true
            }
            .buttonStyle(.borderedProminent)
            
            VStack(spacing: 4) {
                Text("Camera: \(subscriptionManager.getRemainingCameraScans())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Chat: \(subscriptionManager.getRemainingChatRequests())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    PaywallView()
} 