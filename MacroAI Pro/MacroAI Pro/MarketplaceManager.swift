//  MarketplaceManager.swift
//  MacroAI
//
//  Manages diet packs, theme packs, and marketplace purchases

import Foundation
import StoreKit
import SwiftUI
internal import Combine

@MainActor
class MarketplaceManager: ObservableObject {
    static let shared = MarketplaceManager(subscriptionManager: SubscriptionManager.shared)
    
    // MARK: - Published Properties
    
    @Published var dietPacks: [DietPack] = []
    @Published var themePacks: [ThemePack] = []
    @Published var purchaseState = PurchaseState()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let subscriptionManager: SubscriptionManager
    private let fileManager = FileManager.default
    
    // MARK: - Storage
    
    private let purchaseStateKey = "marketplace_purchase_state"
    private let dietPacksCacheKey = "cached_diet_packs"
    private let themePacksCacheKey = "cached_theme_packs"
    
    // MARK: - Initialization
    
    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        
        Task {
            await loadCachedData()
            await loadDefaultPacks()
            await refreshAvailablePacks()
            await autoActivateJuly4thTheme()
        }
    }
    
    // MARK: - Data Loading
    
    func loadCachedData() async {
        // Load purchase state
        if let data = UserDefaults.standard.data(forKey: purchaseStateKey),
           let state = try? JSONDecoder().decode(PurchaseState.self, from: data) {
            purchaseState = state
        }
        
        // Load cached diet packs
        if let data = UserDefaults.standard.data(forKey: dietPacksCacheKey),
           let packs = try? JSONDecoder().decode([DietPack].self, from: data) {
            dietPacks = packs
        }
        
        // Load cached theme packs
        if let data = UserDefaults.standard.data(forKey: themePacksCacheKey),
           let packs = try? JSONDecoder().decode([ThemePack].self, from: data) {
            themePacks = packs
        }
    }
    
    func loadDefaultPacks() async {
        if dietPacks.isEmpty {
            dietPacks = createDefaultDietPacks()
            await cacheDietPacks()
        }
        
        if themePacks.isEmpty { print("🔍 [MarketplaceManager] Loading default theme packs...")
            themePacks = createDefaultThemePacks(); print("✅ [MarketplaceManager] Loaded (themePacks.count) theme packs")
            await cacheThemePacks()
        }
    }
    
    func refreshAvailablePacks() async {
        isLoading = true
        
        // In future, this would fetch from your backend
        // For now, we'll use the default packs and check availability
        
        dietPacks = dietPacks.filter { $0.isAvailable }
        // Don't filter theme packs by availability - show all themes
        // themePacks = themePacks.filter { $0.isAvailable }
        
        isLoading = false
    }
    
    // MARK: - Access Control
    
    func canAccess(dietPack: DietPack) -> Bool {
        // TestFlight users get everything
        if subscriptionManager.isTestFlightUser {
            return true
        }
        
        // Check if already purchased
        if purchaseState.owns(dietPack: dietPack) {
            return true
        }
        
        // Check subscription requirements
        switch dietPack.pricing {
        case .free:
            return true
        case .proRequired:
            return subscriptionManager.currentTier == .pro || subscriptionManager.currentTier == .elite
        case .eliteRequired:
            return subscriptionManager.currentTier == .elite
        case .oneTimePurchase, .seasonal:
            return false // Requires purchase
        }
    }
    
    func canAccess(themePack: ThemePack) -> Bool {
        // TestFlight users get everything
        if subscriptionManager.isTestFlightUser {
            return true
        }
        
        // Check if already purchased
        if purchaseState.owns(themePack: themePack) {
            return true
        }
        
        // Check subscription requirements
        switch themePack.pricing {
        case .free:
            return true
        case .proRequired:
            return subscriptionManager.currentTier == .pro || subscriptionManager.currentTier == .elite
        case .eliteRequired:
            return subscriptionManager.currentTier == .elite
        case .oneTimePurchase, .seasonal:
            return false // Requires purchase
        }
    }
    
    // MARK: - Purchases
    
    func purchase(dietPack: DietPack) async throws {
        guard case let .oneTimePurchase(_, productID) = dietPack.pricing else {
            throw MarketplaceError.invalidPurchase
        }
        
        // Find product and purchase through subscription manager
        guard let product = subscriptionManager.products.first(where: { $0.id == productID }) else {
            throw MarketplaceError.productNotFound
        }
        
        try await subscriptionManager.purchase(product)
        
        // Mark as owned
        purchaseState.purchase(dietPack: dietPack)
        await savePurchaseState()
    }
    
    func purchase(themePack: ThemePack) async throws {
        let productID: String
        
        switch themePack.pricing {
        case .oneTimePurchase(_, let id), .seasonal(_, let id, _):
            productID = id
        default:
            throw MarketplaceError.invalidPurchase
        }
        
        // Find product and purchase through subscription manager
        guard let product = subscriptionManager.products.first(where: { $0.id == productID }) else {
            throw MarketplaceError.productNotFound
        }
        
        try await subscriptionManager.purchase(product)
        
        // Mark as owned
        purchaseState.purchase(themePack: themePack)
        await savePurchaseState()
    }
    
    // MARK: - Data Persistence
    
    private func savePurchaseState() async {
        guard let data = try? JSONEncoder().encode(purchaseState) else { return }
        UserDefaults.standard.set(data, forKey: purchaseStateKey)
    }
    
    private func cacheDietPacks() async {
        guard let data = try? JSONEncoder().encode(dietPacks) else { return }
        UserDefaults.standard.set(data, forKey: dietPacksCacheKey)
    }
    
    private func cacheThemePacks() async {
        guard let data = try? JSONEncoder().encode(themePacks) else { return }
        UserDefaults.standard.set(data, forKey: themePacksCacheKey)
    }
    
    // MARK: - Convenience
    
    var availableDietPacks: [DietPack] {
        dietPacks.filter { $0.isAvailable }
    }
    
    var availableThemePacks: [ThemePack] {
        return themePacks // Show all theme packs regardless of availability
    }
    
    var ownedDietPacks: [DietPack] {
        dietPacks.filter { canAccess(dietPack: $0) }
    }
    
    var ownedThemePacks: [ThemePack] {
        themePacks.filter { canAccess(themePack: $0) }
    }
    
    func dietPacksByCategory(_ category: DietCategory) -> [DietPack] {
        availableDietPacks.filter { $0.category == category }
    }
    
    func themePacksBySeason(_ season: Season?) -> [ThemePack] {
    // MARK: - Season Grouping
    
    func getSeasonGroup(for season: Season?) -> [Season] {
        guard let season = season else { return Season.allCases }
        
        switch season {
        case .christmas, .hanukkah, .yule, .winter:
            return [.christmas, .hanukkah, .yule, .winter]
        case .spring, .easter:
            return [.spring, .easter]
        case .summer:
            return [.summer]
        case .fall, .halloween, .thanksgiving:
            return [.fall, .halloween, .thanksgiving]
        case .fourthOfJuly:
            return [.fourthOfJuly]
        case .valentines:
            return [.valentines]
        case .stPatricks:
            return [.stPatricks]
        case .pride:
            return [.pride]
        case .newyear:
            return [.newyear]
        }
    }

        if let season = season {
            let seasonGroup = getSeasonGroup(for: season)
            return availableThemePacks.filter { $0.season != nil && seasonGroup.contains($0.season!) }
        } else {
            return availableThemePacks
        }
    }
    
    var seasonalThemePacks: [ThemePack] {
        availableThemePacks.filter { $0.season != nil }
    }
    
    // MARK: - Default Data Creation
    
    private func createDefaultDietPacks() -> [DietPack] {
        return [
            // Free/Basic Packs
            DietPack(
                id: "standard",
                name: "Standard",
                summary: "Balanced nutrition for everyday health",
                description: "A well-balanced approach to nutrition focusing on whole foods and moderate portions.",
                macroRanges: MacroRanges(
                    carbs: 45...65,
                    protein: 15...25,
                    fat: 20...35,
                    calories: 1800...2200
                ),
                iconName: "heart.fill",
                category: .lifestyle,
                pricing: .free,
                benefits: ["Balanced nutrition", "Easy to follow", "Sustainable long-term"],
                sampleMeals: ["Grilled chicken with quinoa", "Salmon with sweet potato", "Greek yogurt with berries"],
                isActive: true,
                releaseDate: nil,
                seasonalAvailability: nil
            ),
            
            DietPack(
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
            
            // Pro Required Packs
            DietPack(
                id: "carnivore",
                name: "Carnivore",
                summary: "Animal-based nutrition for optimal health",
                description: "An elimination diet focusing exclusively on animal products for therapeutic benefits.",
                macroRanges: MacroRanges(
                    carbs: 0...5,
                    protein: 25...35,
                    fat: 65...75,
                    calories: 1800...2400
                ),
                iconName: "circle.fill",
                category: .performance,
                pricing: .proRequired,
                benefits: ["Elimination diet", "Reduced inflammation", "Simple meal planning"],
                sampleMeals: ["Ribeye steak", "Grass-fed ground beef", "Wild-caught salmon"],
                isActive: true,
                releaseDate: nil,
                seasonalAvailability: nil
            ),
            
            DietPack(
                id: "intermittent_fasting",
                name: "Intermittent Fasting",
                summary: "Time-restricted eating for metabolic health",
                description: "Combines various eating windows with optimal macro distribution for fasting benefits.",
                macroRanges: MacroRanges(
                    carbs: 40...50,
                    protein: 25...30,
                    fat: 25...35,
                    calories: 1400...1800
                ),
                iconName: "clock.fill",
                category: .performance,
                pricing: .proRequired,
                benefits: ["Improved insulin sensitivity", "Cellular autophagy", "Mental clarity"],
                sampleMeals: ["High-protein breakfast", "Nutrient-dense lunch", "Light dinner"],
                isActive: true,
                releaseDate: nil,
                seasonalAvailability: nil
            ),
            
            // Elite Required Medical Packs
            DietPack(
                id: "diabetic",
                name: "Diabetic",
                summary: "Blood sugar management nutrition",
                description: "Medically-designed nutrition plan for optimal blood glucose control and diabetes management.",
                macroRanges: MacroRanges(
                    carbs: 45...50,
                    protein: 15...20,
                    fat: 30...35,
                    calories: 1600...2000
                ),
                iconName: "cross.fill",
                category: .medical,
                pricing: .eliteRequired,
                benefits: ["Blood sugar control", "Heart health", "Weight management"],
                sampleMeals: ["Lean protein with vegetables", "High-fiber grains", "Controlled portions"],
                isActive: true,
                releaseDate: nil,
                seasonalAvailability: nil
            ),
            
            DietPack(
                id: "gastric_sleeve",
                name: "Gastric Sleeve",
                summary: "Post-surgery nutrition guidance",
                description: "Specialized nutrition plan designed for patients who have undergone gastric sleeve surgery.",
                macroRanges: MacroRanges(
                    carbs: 30...40,
                    protein: 30...40,
                    fat: 25...30,
                    calories: 1000...1400
                ),
                iconName: "medical.thermometer",
                category: .medical,
                pricing: .eliteRequired,
                benefits: ["Post-surgery support", "Protein optimization", "Vitamin absorption"],
                sampleMeals: ["Protein-first approach", "Small frequent meals", "Nutrient-dense foods"],
                isActive: true,
                releaseDate: nil,
                seasonalAvailability: nil
            ),
            
            // Seasonal Diet Packs
            DietPack(
                id: "christmas_2024",
                name: "Christmas Feast",
                summary: "Holiday nutrition without the guilt",
                description: "Enjoy the holidays while maintaining your health goals with smart macro management.",
                macroRanges: MacroRanges(
                    carbs: 40...50,
                    protein: 20...25,
                    fat: 30...40,
                    calories: 2000...2400
                ),
                iconName: "gift.fill",
                category: .seasonal,
                pricing: .seasonal(price: 4.99, productID: "com.FolkTechAI.MacroAI.christmas2024", season: .christmas),
                benefits: ["Holiday meal planning", "Festive recipes", "Guilt-free celebrations"],
                sampleMeals: ["Healthy eggnog protein shake", "Turkey with smart sides", "Christmas cookie alternatives"],
                isActive: true,
                releaseDate: Date(),
                seasonalAvailability: SeasonalAvailability(season: .christmas, availableMonths: [11, 12, 1], startDate: nil, endDate: nil, isYearRound: false)
            ),
            
            DietPack(
                id: "summer_beach_body_2024",
                name: "Summer Beach Body",
                summary: "Light, refreshing nutrition for hot weather",
                description: "A seasonal diet focused on hydrating foods, fresh produce, and lean proteins perfect for summer activities and beach season.",
                macroRanges: MacroRanges(
                    carbs: 40...50,
                    protein: 25...35,
                    fat: 25...35,
                    calories: 1600...2000
                ),
                iconName: "sun.max.fill",
                category: .seasonal,
                pricing: .seasonal(price: 4.99, productID: "com.FolkTechAI.MacroAI.summerbeachbody2024", season: .fourthOfJuly),
                benefits: ["Hydrating foods", "Light summer meals", "Beach-ready nutrition", "Fresh seasonal produce"],
                sampleMeals: ["Watermelon & feta salad", "Grilled fish tacos", "Coconut smoothie bowl", "Cold gazpacho soup"],
                isActive: true,
                releaseDate: Date(),
                seasonalAvailability: SeasonalAvailability(season: .fourthOfJuly, availableMonths: [6, 7, 8], startDate: nil, endDate: nil, isYearRound: false)
            ),
            
            DietPack(
                id: "thanksgiving_prep_2024",
                name: "Thanksgiving Prep",
                summary: "Healthy strategies for holiday indulgence",
                description: "Strategic nutrition plan to help you enjoy Thanksgiving while maintaining your health goals through portion control and mindful eating.",
                macroRanges: MacroRanges(
                    carbs: 35...45,
                    protein: 25...35,
                    fat: 30...40,
                    calories: 1800...2500
                ),
                iconName: "turkey.imageset",
                category: .seasonal,
                pricing: .seasonal(price: 3.99, productID: "com.FolkTechAI.MacroAI.thanksgivingprep2024", season: .thanksgiving),
                benefits: ["Holiday meal strategies", "Portion control tips", "Mindful eating practices", "Post-feast recovery"],
                sampleMeals: ["Lighter breakfast pre-feast", "Veggie-heavy lunch", "Strategic Thanksgiving plate", "Recovery smoothie"],
                isActive: true,
                releaseDate: Date(),
                seasonalAvailability: SeasonalAvailability(season: .thanksgiving, availableMonths: [10, 11, 12], startDate: nil, endDate: nil, isYearRound: false)
            ),
            
            DietPack(
                id: "new_year_reset_2024",
                name: "New Year Reset",
                summary: "Fresh start nutrition for January",
                description: "Clean, energizing nutrition plan to help you start the new year strong with sustainable healthy habits and renewed energy.",
                macroRanges: MacroRanges(
                    carbs: 35...45,
                    protein: 25...35,
                    fat: 25...35,
                    calories: 1600...2200
                ),
                iconName: "sparkles",
                category: .seasonal,
                pricing: .seasonal(price: 5.99, productID: "com.FolkTechAI.MacroAI.newyearreset2024", season: .newyear),
                benefits: ["Detox support", "Energy boosting foods", "Habit reset strategies", "Clean eating focus"],
                sampleMeals: ["Green detox smoothie", "Quinoa power bowl", "Herbal tea blends", "Veggie-packed stir fry"],
                isActive: true,
                releaseDate: Date(),
                seasonalAvailability: SeasonalAvailability(season: .newyear, availableMonths: [1, 2], startDate: nil, endDate: nil, isYearRound: false)
            )
        ]
    }
    
    private func createDefaultThemePacks() -> [ThemePack] {
        return [
            // Easter Theme
            ThemePack(
                id: "easter_theme_2024",
                name: "Easter Joy",
                description: "Celebrate Easter with pastel colors and spring renewal",
                season: .easter,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.eastertheme2024", season: .easter),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 0.9, green: 0.7, blue: 0.9), // Soft Pink
                    secondaryColor: ColorData(red: 0.7, green: 0.9, blue: 0.7), // Soft Green
                    accentColor: ColorData(red: 1.0, green: 1.0, blue: 0.8), // Soft Yellow
                    plateIconName: "easter_egg_plate",
                    backgroundPattern: "easter_eggs",
                    animations: ["floating_eggs", "bunny_hop"]
                ),
                previewImage: "easter_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .easter,
                    availableMonths: [3, 4], // March and April
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 1)),
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 30))
                )
            ),
            
            // Valentine's Theme
            ThemePack(
                id: "valentines_theme_2024",
                name: "Love Bites",
                description: "Romantic reds and pinks for the season of love",
                season: .valentines,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.valentinestheme2024", season: .valentines),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 0.9, green: 0.2, blue: 0.3), // Romantic Red
                    secondaryColor: ColorData(red: 1.0, green: 0.6, blue: 0.8), // Soft Pink
                    accentColor: ColorData(red: 1.0, green: 0.8, blue: 0.9), // Light Pink
                    plateIconName: "heart_plate",
                    backgroundPattern: "hearts",
                    animations: ["floating_hearts", "heart_beat"]
                ),
                previewImage: "valentines_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .valentines,
                    availableMonths: [1, 2], // January and February
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15)),
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 15))
                )
            ),
            
            // Christmas Theme
            ThemePack(
                id: "christmas_theme_2024",
                name: "Christmas Magic",
                description: "Celebrate the holidays with classic red and green Christmas colors",
                season: .christmas,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.christmastheme2024", season: .christmas),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 0.8, green: 0.1, blue: 0.1), // Christmas Red
                    secondaryColor: ColorData(red: 0.0, green: 0.5, blue: 0.0), // Christmas Green
                    accentColor: ColorData(red: 1.0, green: 0.8, blue: 0.0), // Gold
                    plateIconName: "christmas_tree_plate",
                    backgroundPattern: "snowflakes",
                    animations: ["falling_snow", "twinkling_lights"]
                ),
                previewImage: "christmas_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .christmas,
                    availableMonths: [11, 12], // November and December
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 29)), // Black Friday
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 31)) // End of December
                )
            ),
            
            // Hanukkah Theme
            ThemePack(
                id: "hanukkah_theme_2024",
                name: "Festival of Lights",
                description: "Celebrate Hanukkah with the warm glow of the menorah",
                season: .hanukkah,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.hanukkahtheme2024", season: .hanukkah),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 0.0, green: 0.4, blue: 0.8), // Hanukkah Blue
                    secondaryColor: ColorData(red: 0.75, green: 0.75, blue: 0.75), // Silver
                    accentColor: ColorData(red: 1.0, green: 1.0, blue: 1.0), // White
                    plateIconName: "menorah_plate",
                    backgroundPattern: "dreidels",
                    animations: ["candle_flicker", "dreidel_spin"]
                ),
                previewImage: "hanukkah_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .hanukkah,
                    availableMonths: [11, 12], // November and December
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 29)), // Black Friday
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 15)) // End of Hanukkah
                )
            ),
            
            // Yule Theme
            ThemePack(
                id: "yule_theme_2024",
                name: "Yule",
                description: "Celebrate the longest night with Yule traditions",
                season: .yule,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.yuletheme2024", season: .yule),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 0.1, green: 0.3, blue: 0.5), // Deep Winter Blue
                    secondaryColor: ColorData(red: 0.8, green: 0.6, blue: 0.4), // Warm Wood
                    accentColor: ColorData(red: 1.0, green: 0.9, blue: 0.8), // Candle Light
                    plateIconName: "yule_log_plate",
                    backgroundPattern: "evergreen",
                    animations: ["log_burning", "solstice_light"]
                ),
                previewImage: "yule_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .yule,
                    availableMonths: [11, 12], // November and December
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 29)), // Black Friday
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 31)) // End of December
                )
            ),
            

            
            // Halloween Theme
            ThemePack(
                id: "halloween_theme_2024",
                name: "Spooky Treats",
                description: "Halloween magic with pumpkin oranges and spooky purples",
                season: .halloween,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.halloweentheme2024", season: .halloween),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 1.0, green: 0.4, blue: 0.0), // Pumpkin Orange
                    secondaryColor: ColorData(red: 0.4, green: 0.1, blue: 0.6), // Spooky Purple
                    accentColor: ColorData(red: 0.0, green: 0.0, blue: 0.0), // Halloween Black
                    plateIconName: "pumpkin_plate",
                    backgroundPattern: "spider_webs",
                    animations: ["floating_ghosts", "pumpkin_glow"]
                ),
                previewImage: "halloween_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .halloween,
                    availableMonths: [9, 10], // September and October
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 15)), // Mid-September
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 10, day: 31)) // End of October
                )
            ),
            
            // Thanksgiving Theme
            ThemePack(
                id: "thanksgiving_theme_2024",
                name: "Thanksgiving Harvest",
                description: "Celebrate gratitude with warm autumn harvest colors",
                season: .thanksgiving,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.thanksgivingtheme2024", season: .thanksgiving),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 0.8, green: 0.4, blue: 0.1), // Pumpkin Orange
                    secondaryColor: ColorData(red: 0.6, green: 0.3, blue: 0.1), // Brown
                    accentColor: ColorData(red: 1.0, green: 0.8, blue: 0.4), // Corn Yellow
                    plateIconName: "turkey_plate",
                    backgroundPattern: "fall_leaves",
                    animations: ["falling_leaves", "turkey_waddle"]
                ),
                previewImage: "thanksgiving_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .thanksgiving,
                    availableMonths: [10, 11], // October and November
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 10, day: 15)), // Mid-October
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 28)) // Day before Black Friday
                )
            ),
            
            // St. Patrick's Theme
            ThemePack(
                id: "stpatricks_theme_2024",
                name: "Lucky Greens",
                description: "Find your pot of nutritional gold with Irish greens and shamrock magic",
                season: .stPatricks,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.stpatrickstheme2024", season: .stPatricks),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 0.0, green: 0.6, blue: 0.0), // Irish Green
                    secondaryColor: ColorData(red: 0.0, green: 0.4, blue: 0.0), // Forest Green
                    accentColor: ColorData(red: 1.0, green: 0.8, blue: 0.0), // Pot of Gold
                    plateIconName: "shamrock_plate",
                    backgroundPattern: "clovers",
                    animations: ["rainbow_arc", "leprechaun_dance"]
                ),
                previewImage: "stpatricks_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .stPatricks,
                    availableMonths: [2, 3], // February and March
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 15)), // After Valentine's
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 17)) // Day after St. Patrick's
                )
            ),
            
            // Pride Theme
            ThemePack(
                id: "pride_theme_2024",
                name: "Pride Celebration",
                description: "Celebrate diversity and inclusion with vibrant rainbow colors",
                season: .pride,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.pridetheme2024", season: .pride),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 1.0, green: 0.0, blue: 0.0), // Rainbow Red
                    secondaryColor: ColorData(red: 0.0, green: 0.0, blue: 1.0), // Rainbow Blue
                    accentColor: ColorData(red: 1.0, green: 1.0, blue: 0.0), // Rainbow Yellow
                    plateIconName: "rainbow_plate",
                    backgroundPattern: "rainbow_gradient",
                    animations: ["rainbow_sparkles", "pride_celebration"]
                ),
                previewImage: "pride_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .pride,
                    availableMonths: [6], // June
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 1)), // June 1
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 30)) // June 30
                )
            ),
            
            // New Year Theme
            ThemePack(
                id: "newyear_theme_2024",
                name: "New Year Sparkle",
                description: "Ring in the new year with glittering gold and silver sparkles",
                season: .newyear,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.newyeartheme2024", season: .newyear),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 1.0, green: 0.8, blue: 0.0), // Gold
                    secondaryColor: ColorData(red: 0.8, green: 0.8, blue: 0.9), // Silver
                    accentColor: ColorData(red: 1.0, green: 1.0, blue: 1.0), // White
                    plateIconName: "champagne_plate",
                    backgroundPattern: "sparkles",
                    animations: ["fireworks", "champagne_bubbles", "countdown"]
                ),
                previewImage: "newyear_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .newyear,
                    availableMonths: [12, 1], // December and January
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 15)), // Mid-December
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 14)) // Day before Valentine's starts
                )
            ),
            
            // Spring Theme
            ThemePack(
                id: "spring_theme_2024",
                name: "Spring Bloom",
                description: "Welcome spring with cherry blossom pinks and fresh greens",
                season: .spring,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.springtheme2024", season: .spring),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 1.0, green: 0.7, blue: 0.8), // Cherry Blossom Pink
                    secondaryColor: ColorData(red: 0.7, green: 0.9, blue: 0.7), // Fresh Green
                    accentColor: ColorData(red: 1.0, green: 1.0, blue: 0.8), // Soft Yellow
                    plateIconName: "cherry_blossom_plate",
                    backgroundPattern: "flower_petals",
                    animations: ["falling_petals", "butterfly_flutter"]
                ),
                previewImage: "spring_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .spring,
                    availableMonths: [3, 4, 5], // March, April, May
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 18)), // After St. Patrick's
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 5, day: 31)) // End of May
                )
            ),
            
            // Summer Beach Theme
            ThemePack(
                id: "summer_beach_theme_2024",
                name: "Summer Beach",
                description: "Feel the ocean breeze with beach colors and tropical vibes",
                season: .summer,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.summerbeachtheme2024", season: .summer),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 0.2, green: 0.6, blue: 0.9), // Ocean Blue
                    secondaryColor: ColorData(red: 0.9, green: 0.8, blue: 0.6), // Sand Beige
                    accentColor: ColorData(red: 1.0, green: 0.6, blue: 0.3), // Sunset Orange
                    plateIconName: "beach_umbrella_plate",
                    backgroundPattern: "ocean_waves",
                    animations: ["ocean_waves", "beach_ball_bounce", "seagull_flight"]
                ),
                previewImage: "summer_beach_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .summer,
                    availableMonths: [6, 7, 8], // June, July, August
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 1)), // Start of June
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 31)) // End of August
                )
            ),
            
            // Fall Theme
            ThemePack(
                id: "fall_theme_2024",
                name: "Autumn Harvest",
                description: "Embrace fall with rich autumn colors and golden leaves",
                season: .fall,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.falltheme2024", season: .fall),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 0.8, green: 0.4, blue: 0.1), // Pumpkin Orange
                    secondaryColor: ColorData(red: 0.6, green: 0.3, blue: 0.1), // Brown
                    accentColor: ColorData(red: 1.0, green: 0.8, blue: 0.4), // Golden Yellow
                    plateIconName: "maple_leaf_plate",
                    backgroundPattern: "fall_leaves",
                    animations: ["falling_leaves", "pumpkin_glow"]
                ),
                previewImage: "fall_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .fall,
                    availableMonths: [9, 10, 11], // September, October, November
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 1)), // Start of September
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 28)) // Day before Black Friday
                )
            ),
            
            // Winter Theme
            ThemePack(
                id: "winter_theme_2024",
                name: "Winter Wonderland",
                description: "Experience the magic of winter with frosty blues and warm whites",
                season: .winter,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.wintertheme2024", season: .winter),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 0.7, green: 0.8, blue: 1.0), // Frost Blue
                    secondaryColor: ColorData(red: 1.0, green: 1.0, blue: 1.0), // Snow White
                    accentColor: ColorData(red: 0.9, green: 0.9, blue: 0.9), // Ice Gray
                    plateIconName: "snowflake_plate",
                    backgroundPattern: "snowflakes",
                    animations: ["falling_snow", "ice_crystals"]
                ),
                previewImage: "winter_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .winter,
                    availableMonths: [12, 1, 2], // December, January, February
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 1)), // Start of December
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 14)) // Day before Valentine's
                )
            ),
            
            // 4th of July Theme
            ThemePack(
                id: "independence_day_theme_2024",
                name: "Freedom Feast",
                description: "Celebrate America with patriotic red, white, and blue colors plus victory fireworks!",
                season: .fourthOfJuly,
                pricing: .seasonal(price: 2.99, productID: "com.FolkTechAI.MacroAI.july4ththeme2024", season: .fourthOfJuly),
                theme: MarketplaceTheme(
                    primaryColor: ColorData(red: 0.8, green: 0.1, blue: 0.1), // Patriotic Red
                    secondaryColor: ColorData(red: 0.1, green: 0.2, blue: 0.8), // Freedom Blue
                    accentColor: ColorData(red: 1.0, green: 1.0, blue: 1.0), // Pure White
                    plateIconName: "stars_stripes_plate",
                    backgroundPattern: "stars_field",
                    animations: ["fireworks", "star_sparkles", "flag_wave"]
                ),
                previewImage: "july4th_theme_preview",
                isActive: true,
                seasonalAvailability: SeasonalAvailability(
                    season: .fourthOfJuly,
                    availableMonths: [6, 7], // June and July
                    startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15)), // Mid-June
                    endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 7)) // Week after 4th of July
                )
            )
        ]
    }
    
    // MARK: - Active Status Checking
    
    func isActiveDietPack(_ dietPack: DietPack) -> Bool {
        return DietManager.shared.currentDiet.id == dietPack.id
    }
    
    func isActiveThemePack(_ themePack: ThemePack) -> Bool {
        return ThemeManager.shared.currentTheme.id == themePack.id
    }
    
    // MARK: - Activation Methods
    
    func activateDietPack(_ dietPack: DietPack) {
        guard canAccess(dietPack: dietPack) else { return }
        
        // Convert DietPack to Diet for DietManager
        let isPremiumPack: Bool
        switch dietPack.pricing {
        case .free:
            isPremiumPack = false
        case .proRequired, .eliteRequired, .oneTimePurchase, .seasonal:
            isPremiumPack = true
        }
        
        let diet = Diet(
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
            restrictedFoods: [],
            recommendedFoods: dietPack.sampleMeals,
            icon: dietPack.iconName,
            primaryColor: .blue
        )
        
        // Activate in DietManager
        DietManager.shared.selectDiet(diet)
        
        print("✅ [MarketplaceManager] Activated diet pack: \(dietPack.name)")
    }
    
    func activateThemePack(_ themePack: ThemePack) {
        guard canAccess(themePack: themePack) else { return }
        
        // Convert ThemePack to AppTheme for ThemeManager
        let isPremiumTheme: Bool
        switch themePack.pricing {
        case .free:
            isPremiumTheme = false
        case .proRequired, .eliteRequired, .oneTimePurchase, .seasonal:
            isPremiumTheme = true
        }
        
        let appTheme = AppTheme(
            id: themePack.id,
            name: themePack.name,
            description: themePack.description,
            isPremium: isPremiumTheme,
            seasonStart: nil, // Could be enhanced later
            seasonEnd: nil,
            plateStyle: AppTheme.PlateStyle(
                background: themePack.theme.backgroundPattern ?? "none",
                borderColor: colorToHex(themePack.theme.primarySwiftUIColor),
                plateColor: "#FFFFFF"
            ),
            foodIcons: AppTheme.FoodIcons(
                protein: "turkey", // Default for now
                carbs: "potato",
                fats: "butter"
            ),
            colors: AppTheme.ThemeColors(
                primary: colorToHex(themePack.theme.primarySwiftUIColor),
                secondary: colorToHex(themePack.theme.secondarySwiftUIColor),
                accent: colorToHex(themePack.theme.accentSwiftUIColor),
                background: "#F2F2F7"
            ),
            specialEffects: AppTheme.SpecialEffects(
                particles: themePack.theme.animations.first,
                celebrationAnimation: themePack.theme.animations.count > 1 ? themePack.theme.animations[1] : nil,
                overfillEffect: nil
            )
        )
        
        // Activate in ThemeManager
        ThemeManager.shared.selectTheme(appTheme)
        
        print("✅ [MarketplaceManager] Activated theme pack: \(themePack.name)")
    }
    
    // MARK: - Theme Purchase Management
    
    func purchaseTheme(_ themePack: ThemePack) async throws {
        // Simulate purchase process
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // In a real app, this would integrate with StoreKit
        // For now, we'll simulate successful purchase
        
        // Mark theme as purchased (in real app, this would be stored in UserDefaults or Core Data)
        await MainActor.run {
            // Update the theme pack to show as purchased
            // This would typically be stored persistently
            print("Theme purchased: \(themePack.name)")
        }
    }
    
    func isThemePurchased(_ themePack: ThemePack) -> Bool {
        // In a real app, this would check UserDefaults or Core Data
        // For now, return false (simulating not purchased)
        return false
    }
    
    func getAvailableThemes(for season: Season) -> [ThemePack] {
        return themePacks.filter { themePack in
            themePack.season == season && themePack.isAvailable
        }
    }
    
    func getUpcomingThemes(for season: Season) -> [ThemePack] {
        return themePacks.filter { themePack in
            themePack.season == season && !themePack.isAvailable && themePack.isActive
        }
    }
    
    // Helper to convert Color to hex string
    private func colorToHex(_ color: Color) -> String {
        // Get the color components from UIColor
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let redInt = Int(red * 255)
        let greenInt = Int(green * 255)
        let blueInt = Int(blue * 255)
        
        return String(format: "#%02X%02X%02X", redInt, greenInt, blueInt)
    }
    
    // MARK: - Auto-Activation Methods
    
    private func autoActivateJuly4thTheme() async {
        // Find July 4th theme
        guard let july4thTheme = themePacks.first(where: { $0.id == "independence_day_theme_2024" }),
              canAccess(themePack: july4thTheme) else {
            print("❌ [MarketplaceManager] Could not auto-activate July 4th theme")
            return
        }
        
        // Check if a custom theme is already active (not default)
        let currentThemeId = ThemeManager.shared.currentTheme.id
        if currentThemeId != "default" && currentThemeId != "independence_day_theme_2024" {
            print("🎨 [MarketplaceManager] Custom theme already active, skipping auto-activation")
            return
        }
        
        // Auto-activate July 4th theme
        await MainActor.run {
            activateThemePack(july4thTheme)
            print("🇺🇸 [MarketplaceManager] Auto-activated July 4th theme!")
        }
    }

}

// MARK: - Errors

enum MarketplaceError: LocalizedError {
    case invalidPurchase
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidPurchase:
            return "This item cannot be purchased"
        case .productNotFound:
            return "Product not found in store"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        }
    }
} 

