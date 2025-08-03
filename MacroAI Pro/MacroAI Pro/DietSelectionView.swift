// DietSelectionView.swift
// Premium diet selection interface
import SwiftUI
import StoreKit

struct DietSelectionView: View {
    @StateObject private var dietManager = DietManager.shared
    @EnvironmentObject private var storeKit: StoreKitManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var marketplaceManager = MarketplaceManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPremiumSheet = false
    @State private var isShowingMarketplace = false
    @State private var isShowingThemeMarketplace = false
    
    // Computed property to combine standard diets and purchased diet packs
    private var allAvailableDiets: [Diet] {
        var diets = dietManager.availableDiets
        
        // Add purchased diet packs that have been converted to Diet objects
        for dietPack in marketplaceManager.dietPacks {
            if marketplaceManager.canAccess(dietPack: dietPack) {
                // Convert DietPack to Diet for display
                let isPremiumPack: Bool
                switch dietPack.pricing {
                case .free:
                    isPremiumPack = false
                case .proRequired, .eliteRequired, .oneTimePurchase, .seasonal:
                    isPremiumPack = true
                }
                
                let convertedDiet = Diet(
                    id: dietPack.id,
                    name: dietPack.name,
                    description: dietPack.summary,
                    isPremium: isPremiumPack,
                    macroDistribution: Diet.MacroDistribution(
                        protein: Int(dietPack.macroRanges.protein.lowerBound),
                        carbs: Int(dietPack.macroRanges.carbs.lowerBound),
                        fats: Int(dietPack.macroRanges.fat.lowerBound)
                    ),
                    recommendations: Diet.DietRecommendations(
                        dailyCalories: Int(dietPack.macroRanges.calories.lowerBound),
                        mealsPerDay: 3,
                        snacksPerDay: 2,
                        maxNetCarbs: nil,
                        maxCarbsPerMeal: nil,
                        minProteinGrams: nil,
                        maxMealSize: nil
                    ),
                    guidelines: dietPack.benefits,
                    restrictedFoods: nil,
                    recommendedFoods: dietPack.sampleMeals,
                    icon: dietPack.iconName,
                    primaryColor: .blue
                )
                
                // Only add if not already in standard diets
                if !diets.contains(where: { $0.id == convertedDiet.id }) {
                    diets.append(convertedDiet)
                }
            }
        }
        
        return diets
    }
    
    // Computed property for just the purchased diet packs (converted to Diet objects)
    private var purchasedDietPacks: [Diet] {
        var dietPacks: [Diet] = []
        
        for dietPack in marketplaceManager.dietPacks {
            if marketplaceManager.canAccess(dietPack: dietPack) {
                // Convert DietPack to Diet for display
                let isPremiumPack: Bool
                switch dietPack.pricing {
                case .free:
                    isPremiumPack = false
                case .proRequired, .eliteRequired, .oneTimePurchase, .seasonal:
                    isPremiumPack = true
                }
                
                let convertedDiet = Diet(
                    id: dietPack.id,
                    name: dietPack.name,
                    description: dietPack.summary,
                    isPremium: isPremiumPack,
                    macroDistribution: Diet.MacroDistribution(
                        protein: Int(dietPack.macroRanges.protein.lowerBound),
                        carbs: Int(dietPack.macroRanges.carbs.lowerBound),
                        fats: Int(dietPack.macroRanges.fat.lowerBound)
                    ),
                    recommendations: Diet.DietRecommendations(
                        dailyCalories: Int(dietPack.macroRanges.calories.lowerBound),
                        mealsPerDay: 3,
                        snacksPerDay: 2,
                        maxNetCarbs: nil,
                        maxCarbsPerMeal: nil,
                        minProteinGrams: nil,
                        maxMealSize: nil
                    ),
                    guidelines: dietPack.benefits,
                    restrictedFoods: nil,
                    recommendedFoods: dietPack.sampleMeals,
                    icon: dietPack.iconName,
                    primaryColor: .blue
                )
                
                // Only add if not already in standard diets (avoid duplicates)
                if !dietManager.availableDiets.contains(where: { $0.id == convertedDiet.id }) {
                    dietPacks.append(convertedDiet)
                }
            }
        }
        
        return dietPacks
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 20) {
                    standardDietsSection
                    
                    if purchasedDietPacks.count > 0 {
                        purchasedDietPacksSection
                    }
                    
                    marketplaceSection
                }
            }
            .navigationTitle("Diet Selection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var standardDietsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Standard Diet Plans")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dietManager.availableDiets) { diet in
                        DietCard(
                            diet: diet,
                            isSelected: diet.id == dietManager.currentDiet.id,
                            isPremium: storeKit.isPremium || subscriptionManager.isTestFlightUser,
                            onTap: {
                                selectDiet(diet)
                            }
                        )
                        .frame(width: 280)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var purchasedDietPacksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Your Diet Packs", showScrollHint: purchasedDietPacks.count > 1)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(purchasedDietPacks) { diet in
                        DietCard(
                            diet: diet,
                            isSelected: diet.id == dietManager.currentDiet.id,
                            isPremium: storeKit.isPremium || subscriptionManager.isTestFlightUser,
                            isFromMarketplace: true,
                            onTap: {
                                selectDiet(diet)
                            }
                        )
                        .frame(width: 280)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var marketplaceSection: some View {
        VStack(spacing: 20) {
            Text("Want more options?")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                marketplaceButton(
                    title: "Diet Packs",
                    subtitle: "Medical, Performance,\nLifestyle & Seasonal",
                    icon: "heart.text.square.fill",
                    color: .blue
                ) {
                    isShowingMarketplace = true
                }
                
                marketplaceButton(
                    title: "Themes",
                    subtitle: "Customize your\napp appearance",
                    icon: "paintbrush.pointed.fill",
                    color: .purple
                ) {
                    isShowingThemeMarketplace = true
                }
            }
        }
    }
    
    private func sectionHeader(title: String, showScrollHint: Bool = true) -> some View {
        HStack {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Spacer()
            
            if showScrollHint {
                HStack(spacing: 6) {
                    Text("Swipe to see more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }
    
    private func marketplaceButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.1), color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
                    
        }
        .sheet(isPresented: $showingPremiumSheet) {
            PaywallView()
                .environmentObject(storeKit)
        }
        .sheet(isPresented: $isShowingMarketplace) {
            MarketplaceView()
        }
        .sheet(isPresented: $isShowingThemeMarketplace) {
            MarketplaceView()
        }
    }
    
    private func selectDiet(_ diet: Diet) {
        // Check if user has access (either through subscription or TestFlight)
        let hasAccess = storeKit.isPremium || subscriptionManager.isTestFlightUser
        
        if diet.isPremium && !hasAccess {
            showingPremiumSheet = true
            return
        }
        
        dietManager.selectDiet(diet)
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

struct DietCard: View {
    let diet: Diet
    let isSelected: Bool
    let isPremium: Bool
    let onTap: () -> Void
    var isFromMarketplace: Bool = false
    
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon, title, and status indicators
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        // Diet icon with background
                        ZStack {
                            Circle()
                                .fill(diet.primaryColor.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: diet.icon)
                                .foregroundColor(diet.primaryColor)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text(diet.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    Text(diet.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Status indicators
                VStack(alignment: .trailing, spacing: 4) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                    
                    HStack(spacing: 4) {
                        if diet.isPremium {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        
                        if isFromMarketplace {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Enhanced macro distribution visualization
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    EnhancedMacroBar(
                        label: "Protein",
                        percentage: diet.macroDistribution.protein,
                        color: .red
                    )
                    EnhancedMacroBar(
                        label: "Carbs", 
                        percentage: diet.macroDistribution.carbs,
                        color: .green
                    )
                    EnhancedMacroBar(
                        label: "Fats",
                        percentage: diet.macroDistribution.fats,
                        color: .orange
                    )
                }
            }
            
            // Enhanced guidelines preview
            if diet.guidelines.count > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Key Guidelines:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(diet.guidelines.prefix(2)), id: \.self) { guideline in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text(guideline)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    if diet.guidelines.count > 2 {
                        Text("and \(diet.guidelines.count - 2) more...")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
            }
            
            // Lock overlay for premium diets
            if diet.isPremium && !isPremium {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                        Text("Premium")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            isSelected ? diet.primaryColor.opacity(0.1) : Color(.systemBackground),
                            isSelected ? diet.primaryColor.opacity(0.05) : Color(.systemGray6).opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? diet.primaryColor : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: isSelected ? diet.primaryColor.opacity(0.3) : Color.black.opacity(0.1),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
        )
        .onTapGesture {
            onTap()
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct EnhancedMacroBar: View {
    let label: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(percentage)%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(height: 8)
                
                // Progress bar with gradient
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: max(8, CGFloat(percentage) / 100.0 * 60), // 60 is approximate width
                        height: 8
                    )
                    .animation(.easeInOut(duration: 0.3), value: percentage)
            }
        }
    }
}

struct MacroBar: View {
    let label: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 6)
                
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(
                            width: geometry.size.width * CGFloat(percentage) / 100,
                            height: 6
                        )
                }
                .frame(height: 6)
            }
            
            Text("\(percentage)%")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    DietSelectionView()
        .environmentObject(StoreKitManager.shared)
}