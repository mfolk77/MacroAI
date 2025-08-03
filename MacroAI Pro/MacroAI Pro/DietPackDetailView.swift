//  DietPackDetailView.swift
//  MacroAI
//
//  Detailed view for diet pack information and purchase

import SwiftUI

struct DietPackDetailView: View {
    let dietPack: DietPack
    let marketplaceManager: MarketplaceManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var canAccess: Bool {
        marketplaceManager.canAccess(dietPack: dietPack)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    macroBreakdownSection
                    benefitsSection
                    sampleMealsSection
                    
                    if !canAccess {
                        purchaseSection
                    } else if !marketplaceManager.isActiveDietPack(dietPack) {
                        activationSection
                    } else {
                        currentlyActiveSection
                    }
                }
                .padding()
            }
            .navigationTitle(dietPack.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: dietPack.iconName)
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(dietPack.category.displayName)
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        if let season = dietPack.seasonalAvailability?.season {
                            Text(season.emoji + " " + season.displayName)
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        Spacer()
                    }
                    
                    Text(dietPack.summary)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    if canAccess {
                        Label("Unlocked", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label(dietPack.pricing.displayText, systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Text(dietPack.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Macro Breakdown
    
    private var macroBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macro Targets")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                MacroRangeRow(
                    label: "Carbohydrates",
                    range: dietPack.macroRanges.carbs,
                    color: .blue,
                    icon: "leaf.fill"
                )
                
                MacroRangeRow(
                    label: "Protein",
                    range: dietPack.macroRanges.protein,
                    color: .red,
                    icon: "flame.fill"
                )
                
                MacroRangeRow(
                    label: "Fat",
                    range: dietPack.macroRanges.fat,
                    color: .orange,
                    icon: "drop.fill"
                )
                
                MacroRangeRow(
                    label: "Calories",
                    range: dietPack.macroRanges.calories,
                    color: .green,
                    icon: "bolt.fill"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Benefits")
                .font(.title3.bold())
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(dietPack.benefits, id: \.self) { benefit in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(benefit)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
        }
    }
    
    // MARK: - Sample Meals
    
    private var sampleMealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sample Meals")
                .font(.title3.bold())
            
            VStack(spacing: 8) {
                ForEach(Array(dietPack.sampleMeals.enumerated()), id: \.offset) { index, meal in
                    HStack {
                        Text("\(index + 1).")
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text(meal)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Get Access")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                switch dietPack.pricing {
                case .free:
                    // This shouldn't happen if canAccess is false
                    EmptyView()
                    
                case .proRequired:
                    SubscriptionRequiredCard(
                        tier: "Pro",
                        message: "Upgrade to Pro to unlock this diet plan and more premium features.",
                        action: { /* Navigate to paywall */ }
                    )
                    
                case .eliteRequired:
                    SubscriptionRequiredCard(
                        tier: "Elite",
                        message: "Upgrade to Elite to unlock this medical diet plan and advanced features.",
                        action: { /* Navigate to paywall */ }
                    )
                    
                case .oneTimePurchase(let price, _), .seasonal(let price, _, _):
                    PurchaseCard(
                        price: price,
                        isPurchasing: isPurchasing,
                        action: purchaseDietPack
                    )
                }
            }
        }
    }
    
    // MARK: - Activation Section
    
    private var activationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ready to Activate")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You own this diet pack")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Tap activate to start using this nutrition plan and update your macro targets.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
                
                Button(action: activateDietPack) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Activate \(dietPack.name)")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    // MARK: - Currently Active Section
    
    private var currentlyActiveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Currently Active")
                .font(.title3.bold())
            
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("This is your active diet plan")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Your macro targets are set according to this nutrition plan.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Purchase Action
    
    private func purchaseDietPack() {
        Task {
            isPurchasing = true
            
            do {
                try await marketplaceManager.purchase(dietPack: dietPack)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            isPurchasing = false
        }
    }
    
    // MARK: - Activation Action
    
    private func activateDietPack() {
        marketplaceManager.activateDietPack(dietPack)
        
        // Show success feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Supporting Views

struct MacroRangeRow: View {
    let label: String
    let range: ClosedRange<Int>
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(range.lowerBound)-\(range.upperBound)g")
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
    }
}

struct SubscriptionRequiredCard: View {
    let tier: String
    let message: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.blue)
                Text("Requires \(tier)")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: action) {
                Text("Upgrade to \(tier)")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PurchaseCard: View {
    let price: Double
    let isPurchasing: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.green)
                Text("One-time Purchase")
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                Text("$\(String(format: "%.2f", price))")
                    .font(.title3.bold())
                    .foregroundColor(.green)
            }
            
            Text("Unlock this diet plan permanently with a one-time purchase.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: action) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Purchase for $\(String(format: "%.2f", price))")
                            .font(.subheadline.bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(isPurchasing)
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    DietPackDetailView(
        dietPack: DietPack(
            id: "keto",
            name: "Ketogenic",
            summary: "High-fat, low-carb for metabolic benefits",
            description: "A high-fat, moderate-protein, low-carbohydrate diet designed to shift your body into ketosis.",
            macroRanges: MacroRanges(
                carbs: 5...10,
                protein: 20...25,
                fat: 70...80,
                calories: 1600...2000
            ),
            iconName: "flame.fill",
            category: .lifestyle,
            pricing: .free,
            benefits: ["Rapid weight loss", "Mental clarity", "Reduced inflammation"],
            sampleMeals: ["Avocado and bacon salad", "Fatty fish with leafy greens", "Cheese and nuts"],
            isActive: true,
            releaseDate: nil,
            seasonalAvailability: nil
        ),
        marketplaceManager: MarketplaceManager(subscriptionManager: SubscriptionManager.shared)
    )
} 