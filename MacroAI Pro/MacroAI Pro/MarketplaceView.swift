//  MarketplaceView.swift
//  MacroAI
//
//  Diet Marketplace UI with diet packs and seasonal themes

import SwiftUI

struct MarketplaceView: View {
    @StateObject private var marketplaceManager = MarketplaceManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: DietCategory = .lifestyle
    @State private var selectedSeason: Season? = nil
    @State private var showingThemes = false
    @State private var showingPurchaseSheet = false
    @State private var selectedDietPack: DietPack?
    @State private var selectedThemePack: ThemePack?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    categoryTabs
                    
                    if selectedCategory == .seasonal {
                        themePacksSection
                    } else {
                        dietPacksSection
                    }
                }
                .padding()
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedDietPack) { dietPack in
                DietPackDetailView(
                    dietPack: dietPack,
                    marketplaceManager: marketplaceManager
                )
            }
            .sheet(item: $selectedThemePack) { themePack in
                ThemePackDetailView(
                    themePack: themePack,
                    marketplaceManager: marketplaceManager
                )
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "bag.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Diet Packs & Themes")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Discover personalized diet plans and beautiful themes")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            // Premium status indicator
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .semibold))
                
                Text("TestFlight: All content unlocked")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Category Tabs
    
    private var categoryTabs: some View {
        VStack(spacing: 16) {
            // Main category tabs
            HStack(spacing: 12) {
                CategoryTab(
                    category: .lifestyle,
                    isSelected: selectedCategory == .lifestyle,
                    action: { selectedCategory = .lifestyle }
                )
                
                CategoryTab(
                    category: .medical,
                    isSelected: selectedCategory == .medical,
                    action: { selectedCategory = .medical }
                )
                
                CategoryTab(
                    category: .seasonal,
                    isSelected: selectedCategory == .seasonal,
                    action: { selectedCategory = .seasonal }
                )
            }
            .padding(.horizontal)
            
            // Seasonal theme tabs (only show when seasonal is selected)
            if selectedCategory == .seasonal {
                // Clean, organized seasonal theme layout
                VStack(spacing: 12) {
                    // "All Themes" button
                    ThemeSeasonTab(
                        season: nil,
                        isSelected: selectedSeason == nil,
                        action: { selectedSeason = nil }
                    )
                    
                    // First row: Winter Holidays, Spring, Summer
                    HStack(spacing: 12) {
                        ThemeSeasonTab(
                            season: .christmas,
                            isSelected: selectedSeason == .christmas,
                            action: { selectedSeason = .christmas }
                        )
                        
                        ThemeSeasonTab(
                            season: .spring,
                            isSelected: selectedSeason == .spring,
                            action: { selectedSeason = .spring }
                        )
                        
                        ThemeSeasonTab(
                            season: .fourthOfJuly,
                            isSelected: selectedSeason == .fourthOfJuly,
                            action: { selectedSeason = .fourthOfJuly }
                        )
                    }
                    
                    // Second row: Fall, Valentine's, St. Patrick's
                    HStack(spacing: 12) {
                        ThemeSeasonTab(
                            season: .fall,
                            isSelected: selectedSeason == .fall,
                            action: { selectedSeason = .fall }
                        )
                        
                        ThemeSeasonTab(
                            season: .valentines,
                            isSelected: selectedSeason == .valentines,
                            action: { selectedSeason = .valentines }
                        )
                        
                        ThemeSeasonTab(
                            season: .stPatricks,
                            isSelected: selectedSeason == .stPatricks,
                            action: { selectedSeason = .stPatricks }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Diet Packs Section
    
    private var dietPacksSection: some View {
        let packs = marketplaceManager.dietPacksByCategory(selectedCategory)
        
        return Group {
            if packs.isEmpty {
                EmptyStateView(
                    icon: "heart.text.square",
                    title: "No \(selectedCategory.displayName) Packs",
                    subtitle: "Check back soon for new diet plans!"
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(packs) { dietPack in
                        DietPackCard(
                            dietPack: dietPack,
                            canAccess: marketplaceManager.canAccess(dietPack: dietPack),
                            action: { selectedDietPack = dietPack }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Theme Packs Section
    
    private var themePacksSection: some View {
        let themes = marketplaceManager.themePacksBySeason(selectedSeason)
        
        return Group {
            if themes.isEmpty {
                EmptyStateView(
                    icon: "paintbrush.pointed.fill",
                    title: "No Themes Available",
                    subtitle: "Check back soon for new themes!"
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(themes) { themePack in
                        ThemePackCard(
                            themePack: themePack,
                            canAccess: marketplaceManager.canAccess(themePack: themePack),
                            action: { selectedThemePack = themePack }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let category: DietCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Theme Season Tab

struct ThemeSeasonTab: View {
    let season: Season?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(season?.emoji ?? "🎨")
                    .font(.title2)
                
                Text(season?.displayName ?? "All Themes")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Theme Pack Card

struct ThemePackCard: View {
    let themePack: ThemePack
    let canAccess: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Theme preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: themePack.theme.primaryColor.red, green: themePack.theme.primaryColor.green, blue: themePack.theme.primaryColor.blue))
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            Text(themePack.season?.emoji ?? "🎨")
                                .font(.largeTitle)
                            Text(themePack.name)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    )
                
                VStack(spacing: 4) {
                    Text(themePack.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(themePack.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Pricing
                    HStack {
                        if canAccess {
                            Text("Owned")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        } else {
                            Text(themePack.pricing.displayText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 8)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Diet Pack Card

struct DietPackCard: View {
    let dietPack: DietPack
    let canAccess: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Enhanced diet pack preview with gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.8),
                                    Color.purple.opacity(0.6),
                                    Color.blue.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 140)
                    
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text(dietPack.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Premium badge if applicable
                    if dietPack.pricing != .free {
                        VStack {
                            HStack {
                                Spacer()
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.yellow)
                                        .frame(width: 24, height: 24)
                                    
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                            
                            Spacer()
                        }
                    }
                }
                
                VStack(spacing: 8) {
                    Text(dietPack.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(dietPack.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Enhanced pricing display
                    HStack {
                        if canAccess {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.green)
                                
                                Text("Owned")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.blue)
                                
                                Text(dietPack.pricing.displayText)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

