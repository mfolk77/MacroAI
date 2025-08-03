//  DietPack.swift
//  MacroAI
//
//  Diet Marketplace data models and architecture

import Foundation
import SwiftUI

// MARK: - Diet Pack Models

struct DietPack: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let summary: String
    let description: String
    let macroRanges: MacroRanges
    let iconName: String
    let category: DietCategory
    let pricing: DietPricing
    let benefits: [String]
    let sampleMeals: [String]
    let isActive: Bool
    let releaseDate: Date?
    let seasonalAvailability: SeasonalAvailability?
    
    var isAvailable: Bool {
        guard isActive else { return false }
        
        if let seasonal = seasonalAvailability {
            return seasonal.isCurrentlyAvailable
        }
        
        return true
    }
}

struct MacroRanges: Codable, Hashable {
    let carbs: ClosedRange<Int>
    let protein: ClosedRange<Int> 
    let fat: ClosedRange<Int>
    let calories: ClosedRange<Int>
    
    var displayString: String {
        return "C: \(carbs.lowerBound)-\(carbs.upperBound)g | P: \(protein.lowerBound)-\(protein.upperBound)g | F: \(fat.lowerBound)-\(fat.upperBound)g"
    }
    
    // Custom coding for ClosedRange
    enum CodingKeys: String, CodingKey {
        case carbsMin, carbsMax, proteinMin, proteinMax, fatMin, fatMax, caloriesMin, caloriesMax
    }
    
    init(carbs: ClosedRange<Int>, protein: ClosedRange<Int>, fat: ClosedRange<Int>, calories: ClosedRange<Int>) {
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.calories = calories
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let carbsMin = try container.decode(Int.self, forKey: .carbsMin)
        let carbsMax = try container.decode(Int.self, forKey: .carbsMax)
        let proteinMin = try container.decode(Int.self, forKey: .proteinMin)
        let proteinMax = try container.decode(Int.self, forKey: .proteinMax)
        let fatMin = try container.decode(Int.self, forKey: .fatMin)
        let fatMax = try container.decode(Int.self, forKey: .fatMax)
        let caloriesMin = try container.decode(Int.self, forKey: .caloriesMin)
        let caloriesMax = try container.decode(Int.self, forKey: .caloriesMax)
        
        self.carbs = carbsMin...carbsMax
        self.protein = proteinMin...proteinMax
        self.fat = fatMin...fatMax
        self.calories = caloriesMin...caloriesMax
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(carbs.lowerBound, forKey: .carbsMin)
        try container.encode(carbs.upperBound, forKey: .carbsMax)
        try container.encode(protein.lowerBound, forKey: .proteinMin)
        try container.encode(protein.upperBound, forKey: .proteinMax)
        try container.encode(fat.lowerBound, forKey: .fatMin)
        try container.encode(fat.upperBound, forKey: .fatMax)
        try container.encode(calories.lowerBound, forKey: .caloriesMin)
        try container.encode(calories.upperBound, forKey: .caloriesMax)
    }
}

enum DietCategory: String, Codable, CaseIterable {
    case medical = "medical"
    case performance = "performance"
    case lifestyle = "lifestyle"
    case seasonal = "seasonal"
    
    var displayName: String {
        switch self {
        case .medical: return "Medical"
        case .performance: return "Performance"
        case .lifestyle: return "Lifestyle"
        case .seasonal: return "Seasonal"
        }
    }
    
    var icon: String {
        switch self {
        case .medical: return "cross.fill"
        case .performance: return "figure.strengthtraining.traditional"
        case .lifestyle: return "leaf.fill"
        case .seasonal: return "sparkles"
        }
    }
}

enum DietPricing: Codable, Hashable {
    case free
    case proRequired
    case eliteRequired
    case oneTimePurchase(price: Double, productID: String)
    case seasonal(price: Double, productID: String, season: Season)
    
    var displayText: String {
        switch self {
        case .free: return "Free"
        case .proRequired: return "Pro Required"
        case .eliteRequired: return "Elite Required"
        case .oneTimePurchase(let price, _): return "$\(String(format: "%.2f", price))"
        case .seasonal(let price, _, _): return "$\(String(format: "%.2f", price))"
        }
    }
    
    var requiresSubscription: Bool {
        switch self {
        case .free, .oneTimePurchase, .seasonal: return false
        case .proRequired, .eliteRequired: return true
        }
    }
}

struct SeasonalAvailability: Codable, Hashable {
    let season: Season
    let availableMonths: [Int] // 1-12 for Jan-Dec
    let startDate: Date? // Optional specific start date
    let endDate: Date? // Optional specific end date
    let isYearRound: Bool // If true, available all year
    
    init(season: Season, availableMonths: [Int], startDate: Date? = nil, endDate: Date? = nil, isYearRound: Bool = false) {
        self.season = season
        self.availableMonths = availableMonths
        self.startDate = startDate
        self.endDate = endDate
        self.isYearRound = isYearRound
    }
    
    var isCurrentlyAvailable: Bool {
        if isYearRound { return true }
        
        let now = Date()
        
        // Check specific date range if provided
        if let startDate = startDate, let endDate = endDate {
            return now >= startDate && now <= endDate
        }
        
        // Fall back to month-based availability
        let currentMonth = Calendar.current.component(.month, from: now)
        return availableMonths.contains(currentMonth)
    }
    
    var nextAvailableDate: Date? {
        guard !isYearRound else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        
        if let startDate = startDate, now < startDate {
            return startDate
        }
        
        // Find next month in available months
        let currentMonth = calendar.component(.month, from: now)
        let nextAvailableMonth = availableMonths.first { $0 > currentMonth } ?? availableMonths.first
        
        if let nextMonth = nextAvailableMonth {
            var components = calendar.dateComponents([.year, .month], from: now)
            components.month = nextMonth
            if nextMonth < currentMonth {
                components.year = (components.year ?? 0) + 1
            }
            return calendar.date(from: components)
        }
        
        return nil
    }
}

enum Season: String, Codable, CaseIterable {
    case spring = "spring"
    case easter = "easter"
    case fourthOfJuly = "fourthOfJuly"
    case summer = "summer"
    case fall = "fall"
    case halloween = "halloween"
    case thanksgiving = "thanksgiving"
    case christmas = "christmas"
    case hanukkah = "hanukkah"
    case yule = "yule"
    case newyear = "newyear"
    case valentines = "valentines"
    case stPatricks = "stPatricks"
    case pride = "pride"
    case winter = "winter"
    
    var displayName: String {
        switch self {
        case .spring: return "Spring"
        case .easter: return "Easter"
        case .fourthOfJuly: return "4th of July"
        case .summer: return "Summer"
        case .fall: return "Fall"
        case .halloween: return "Halloween"
        case .thanksgiving: return "Thanksgiving"
        case .christmas: return "Christmas"
        case .hanukkah: return "Hanukkah"
        case .yule: return "Yule"
        case .newyear: return "New Year"
        case .valentines: return "Valentine's Day"
        case .stPatricks: return "St. Patrick's Day"
        case .pride: return "Pride"
        case .winter: return "Winter"
        }
    }
    
    var emoji: String {
        switch self {
        case .spring: return "🌸"
        case .easter: return "🐰"
        case .fourthOfJuly: return "🎆"
        case .summer: return "🏖️"
        case .fall: return "🍂"
        case .halloween: return "🎃"
        case .thanksgiving: return "🦃"
        case .christmas: return "🎄"
        case .hanukkah: return "🕎"
        case .yule: return "🌲"
        case .newyear: return "🎊"
        case .valentines: return "💝"
        case .stPatricks: return "🍀"
        case .pride: return "🌈"
        case .winter: return "❄️"
        }
    }
    
    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .easter: return "hare.fill"
        case .fourthOfJuly: return "burst.fill"
        case .summer: return "beach.umbrella.fill"
        case .fall: return "leaf.arrow.circlepath"
        case .halloween: return "moon.fill"
        case .thanksgiving: return "house.fill"
        case .christmas: return "gift.fill"
        case .hanukkah: return "flame.fill"
        case .yule: return "tree.fill"
        case .newyear: return "sparkles"
        case .valentines: return "heart.fill"
        case .stPatricks: return "clover.fill"
        case .pride: return "rainbow"
        case .winter: return "snowflake"
        }
    }
}

// MARK: - Theme Pack Models

struct ThemePack: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let season: Season?
    let pricing: DietPricing
    let theme: MarketplaceTheme
    let previewImage: String
    let isActive: Bool
    let seasonalAvailability: SeasonalAvailability?
    let isPurchased: Bool // Track if user has purchased this theme
    
    init(id: String, name: String, description: String, season: Season?, pricing: DietPricing, theme: MarketplaceTheme, previewImage: String, isActive: Bool, seasonalAvailability: SeasonalAvailability?, isPurchased: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.season = season
        self.pricing = pricing
        self.theme = theme
        self.previewImage = previewImage
        self.isActive = isActive
        self.seasonalAvailability = seasonalAvailability
        self.isPurchased = isPurchased
    }
    
    var isAvailable: Bool {
        guard isActive else { return false }
        
        // If purchased, always available
        if isPurchased { return true }
        
        if let seasonal = seasonalAvailability {
            return seasonal.isCurrentlyAvailable
        }
        
        return true
    }
    
    var availabilityMessage: String? {
        guard let seasonal = seasonalAvailability, !isPurchased else { return nil }
        
        if seasonal.isCurrentlyAvailable {
            return nil
        }
        
        if let nextDate = seasonal.nextAvailableDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Check back on \(formatter.string(from: nextDate)) for this seasonal theme!"
        }
        
        return "This theme will be available during its season. Check back later!"
    }
}

struct MarketplaceTheme: Codable, Hashable {
    let primaryColor: ColorData
    let secondaryColor: ColorData
    let accentColor: ColorData
    let plateIconName: String
    let backgroundPattern: String?
    let animations: [String] // Animation identifiers
    
    var primarySwiftUIColor: Color {
        Color(red: primaryColor.red, green: primaryColor.green, blue: primaryColor.blue, opacity: primaryColor.alpha)
    }
    
    var secondarySwiftUIColor: Color {
        Color(red: secondaryColor.red, green: secondaryColor.green, blue: secondaryColor.blue, opacity: secondaryColor.alpha)
    }
    
    var accentSwiftUIColor: Color {
        Color(red: accentColor.red, green: accentColor.green, blue: accentColor.blue, opacity: accentColor.alpha)
    }
}

struct ColorData: Codable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    init(color: Color) {
        // This is a simplified version - in production you'd want proper color extraction
        self.red = 0.0
        self.green = 0.0
        self.blue = 1.0
        self.alpha = 1.0
    }
}

// MARK: - Purchase State

struct PurchaseState: Codable {
    var ownedDietPacks: Set<String> = []
    var ownedThemePacks: Set<String> = []
    var lastUpdated: Date = Date()
    
    func owns(dietPack: DietPack) -> Bool {
        return ownedDietPacks.contains(dietPack.id)
    }
    
    func owns(themePack: ThemePack) -> Bool {
        return ownedThemePacks.contains(themePack.id)
    }
    
    mutating func purchase(dietPack: DietPack) {
        ownedDietPacks.insert(dietPack.id)
        lastUpdated = Date()
    }
    
    mutating func purchase(themePack: ThemePack) {
        ownedThemePacks.insert(themePack.id)
        lastUpdated = Date()
    }
} 