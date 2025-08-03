//  ThemePackDetailView.swift
//  MacroAI
//
//  Detailed view for theme pack information and purchase

import SwiftUI

struct ThemePackDetailView: View {
    let themePack: ThemePack
    let marketplaceManager: MarketplaceManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isPreviewMode = false
    
    private var canAccess: Bool {
        marketplaceManager.canAccess(themePack: themePack)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    themePreviewSection
                    colorPaletteSection
                    
                    if !themePack.theme.animations.isEmpty {
                        animationsSection
                    }
                    
                    if !canAccess {
                        purchaseSection
                    } else if !marketplaceManager.isActiveThemePack(themePack) {
                        activationSection
                    } else {
                        currentlyActiveSection
                    }
                }
                .padding()
            }
            .navigationTitle(themePack.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if canAccess {
                        Button(action: { isPreviewMode.toggle() }) {
                            Text(isPreviewMode ? "Exit Preview" : "Preview")
                                .font(.caption.bold())
                        }
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .preferredColorScheme(isPreviewMode ? .dark : nil) // Simple preview simulation
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themePack.theme.primarySwiftUIColor)
                        .frame(width: 80, height: 80)
                    
                    Text(themePack.season?.emoji ?? "🎨")
                        .font(.system(size: 40))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let season = themePack.season {
                            Text(season.emoji + " " + season.displayName)
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        if let availability = themePack.seasonalAvailability {
                            Text(availability.isCurrentlyAvailable ? "Available Now" : "Coming Soon")
                                .font(.caption.bold())
                                .foregroundColor(availability.isCurrentlyAvailable ? .green : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background((availability.isCurrentlyAvailable ? Color.green : Color.secondary).opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        Spacer()
                    }
                    
                    Text(themePack.description)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    if canAccess {
                        Label("Unlocked", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label(themePack.pricing.displayText, systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    // Show availability message for seasonal themes
                    if let availabilityMessage = themePack.availabilityMessage {
                        Text(availabilityMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            
            if isPreviewMode {
                Text("🎨 Preview Mode Active")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themePack.theme.primarySwiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Theme Preview Section
    
    private var themePreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Theme Preview")
                .font(.title3.bold())
            
            // Mock app interface preview
            VStack(spacing: 0) {
                // Mock navigation bar
                HStack {
                    Text("MacroAI")
                        .font(.headline.bold())
                        .foregroundColor(isPreviewMode ? .white : .primary)
                    Spacer()
                    Image(systemName: "gear")
                        .foregroundColor(isPreviewMode ? themePack.theme.accentSwiftUIColor : .blue)
                }
                .padding()
                .background(isPreviewMode ? themePack.theme.primarySwiftUIColor : Color(.systemBackground))
                
                // Mock content area
                VStack(spacing: 16) {
                    HStack {
                        // Mock plate view
                        Circle()
                            .fill(isPreviewMode ? themePack.theme.secondarySwiftUIColor : .blue)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "fork.knife.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's Macros")
                                .font(.headline)
                                .foregroundColor(isPreviewMode ? .white : .primary)
                            Text("2,150 / 2,200 calories")
                                .font(.subheadline)
                                .foregroundColor(isPreviewMode ? themePack.theme.accentSwiftUIColor : .secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Mock buttons
                    HStack(spacing: 12) {
                        Button("Snap Food") {  }
                            .padding()
                            .background(isPreviewMode ? themePack.theme.accentSwiftUIColor : .blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button("Manual Entry") {  }
                            .padding()
                            .background(isPreviewMode ? themePack.theme.secondarySwiftUIColor.opacity(0.2) : Color(.systemGray6))
                            .foregroundColor(isPreviewMode ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(isPreviewMode ? themePack.theme.primarySwiftUIColor.opacity(0.3) : Color(.systemGray6))
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPreviewMode ? themePack.theme.accentSwiftUIColor : Color.clear, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Color Palette Section
    
    private var colorPaletteSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Color Palette")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                ColorSwatchRow(
                    label: "Primary",
                    color: themePack.theme.primarySwiftUIColor,
                    description: "Main interface elements"
                )
                
                ColorSwatchRow(
                    label: "Secondary",
                    color: themePack.theme.secondarySwiftUIColor,
                    description: "Supporting elements"
                )
                
                ColorSwatchRow(
                    label: "Accent",
                    color: themePack.theme.accentSwiftUIColor,
                    description: "Buttons and highlights"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Animations Section
    
    private var animationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Special Effects")
                .font(.title3.bold())
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(themePack.theme.animations, id: \.self) { animation in
                    VStack(spacing: 8) {
                        Image(systemName: animationIcon(for: animation))
                            .font(.title2)
                            .foregroundColor(themePack.theme.accentSwiftUIColor)
                        
                        Text(animation.capitalized)
                            .font(.caption.bold())
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
        }
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Get This Theme")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                switch themePack.pricing {
                case .free:
                    EmptyView()
                    
                case .proRequired:
                    SubscriptionRequiredCard(
                        tier: "Pro",
                        message: "Upgrade to Pro to unlock this theme and more premium features.",
                        action: { /* Navigate to paywall */ }
                    )
                    
                case .eliteRequired:
                    SubscriptionRequiredCard(
                        tier: "Elite",
                        message: "Upgrade to Elite to unlock this theme and advanced features.",
                        action: { /* Navigate to paywall */ }
                    )
                    
                case .oneTimePurchase(let price, _), .seasonal(let price, _, _):
                    ThemePurchaseCard(
                        price: price,
                        isPurchasing: isPurchasing,
                        action: purchaseThemePack
                    )
                }
            }
        }
    }
    
    // MARK: - Activation Section
    
    private var activationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ready to Apply")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You own this theme pack")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Tap apply to start using this theme throughout the app.")
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
                
                Button(action: activateThemePack) {
                    HStack {
                        Image(systemName: "paintbrush.pointed.fill")
                        Text("Apply \(themePack.name)")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themePack.theme.primarySwiftUIColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    // MARK: - Currently Active Section
    
    private var currentlyActiveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Currently Applied")
                .font(.title3.bold())
            
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("This is your active theme")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("This theme is currently applied throughout the app.")
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
    
    private func purchaseThemePack() {
        Task {
            isPurchasing = true
            
            do {
                try await marketplaceManager.purchase(themePack: themePack)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            isPurchasing = false
        }
    }
    
    // MARK: - Activation Action
    
    private func activateThemePack() {
        marketplaceManager.activateThemePack(themePack)
        
        // Show success feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    // MARK: - Helper Functions
    
    private func animationIcon(for animation: String) -> String {
        switch animation.lowercased() {
        case "snowfall", "snowflakes":
            return "snow"
        case "sparkle", "sparkles", "star_sparkles":
            return "sparkles"
        case "falling_leaves":
            return "leaf.fill"
        case "fireworks":
            return "burst"
        case "flag_wave":
            return "flag.fill"
        default:
            return "star.fill"
        }
    }
}

// MARK: - Supporting Views

struct ColorSwatchRow: View {
    let label: String
    let color: Color
    let description: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ThemePurchaseCard: View {
    let price: Double
    let isPurchasing: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paintbrush.pointed.fill")
                    .foregroundColor(.purple)
                Text("Theme Pack")
                    .font(.headline)
                    .foregroundColor(.purple)
                Spacer()
                Text("$\(String(format: "%.2f", price))")
                    .font(.title3.bold())
                    .foregroundColor(.purple)
            }
            
            Text("Transform your app's appearance with this beautiful theme.")
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
                .background(Color.purple)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(isPurchasing)
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ThemePackDetailView(
        themePack: ThemePack(
            id: "christmas_theme_2024",
            name: "Christmas Magic",
            description: "Transform your app with festive Christmas colors and animations",
            season: .christmas,
            pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.christmastheme2024", season: .christmas),
            theme: MarketplaceTheme(
                primaryColor: ColorData(red: 0.8, green: 0.1, blue: 0.1),
                secondaryColor: ColorData(red: 0.1, green: 0.6, blue: 0.1),
                accentColor: ColorData(red: 1.0, green: 0.8, blue: 0.0),
                plateIconName: "christmas_plate",
                backgroundPattern: "snowflakes",
                animations: ["snowfall", "sparkle"]
            ),
            previewImage: "christmas_theme_preview",
            isActive: false,
            seasonalAvailability: SeasonalAvailability(season: .christmas, availableMonths: [11, 12, 1])
        ),
        marketplaceManager: MarketplaceManager.shared
    )
} 