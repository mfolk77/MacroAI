// ThemeManager.swift
// Manages seasonal themes and premium theme packs
import Foundation
import SwiftUI
internal import Combine

struct AppTheme: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let isPremium: Bool
    let seasonStart: String? // MM-dd format
    let seasonEnd: String?   // MM-dd format
    let plateStyle: PlateStyle
    let foodIcons: FoodIcons
    let colors: ThemeColors
    let specialEffects: SpecialEffects?
    
    struct PlateStyle: Codable, Equatable {
        let background: String
        let borderColor: String
        let plateColor: String
    }
    
    struct FoodIcons: Codable, Equatable {
        let protein: String
        let carbs: String
        let fats: String
    }
    
    struct ThemeColors: Codable, Equatable {
        let primary: String
        let secondary: String
        let accent: String
        let background: String
    }
    
    struct SpecialEffects: Codable, Equatable {
        let particles: String?
        let celebrationAnimation: String?
        let overfillEffect: String?
        
    }
}

@MainActor
class ThemeManager: ObservableObject {
    @Published var availableThemes: [AppTheme] = []
    @Published var currentTheme: AppTheme
    @Published var isSeasonalThemeActive: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let currentThemeKey = "selectedTheme"
    
    // Default theme
    private let defaultTheme = AppTheme(
        id: "default",
        name: "Classic",
        description: "Clean and modern design",
        isPremium: false,
        seasonStart: nil,
        seasonEnd: nil,
        plateStyle: AppTheme.PlateStyle(
            background: "none",
            borderColor: "#E5E5E7",
            plateColor: "#FFFFFF"
        ),
        foodIcons: AppTheme.FoodIcons(
            protein: "turkey",
            carbs: "potato", 
            fats: "butter"
        ),
        colors: AppTheme.ThemeColors(
            primary: "#007AFF",
            secondary: "#5856D6",
            accent: "#FF9500",
            background: "#F2F2F7"
        ),
        specialEffects: nil
    )
    
    init() {
        self.currentTheme = defaultTheme
        loadThemes()
        loadSavedTheme()
        checkSeasonalThemes()
    }
    
    // MARK: - Theme Loading
    
    private func loadThemes() {
        // Load themes from JSON files and also include marketplace themes
        let themeFiles = ["thanksgiving", "christmas", "pride", "hanukkah", "easter", "halloween", "valentines", "new_year"]
        var themes: [AppTheme] = [defaultTheme]
        
        for themeFile in themeFiles {
            if let theme = loadTheme(from: themeFile) {
                themes.append(theme)
            }
        }
        
        // Add hardcoded marketplace themes that aren't in JSON files
        themes.append(contentsOf: createMarketplaceThemes())
        
        self.availableThemes = themes
        print("✅ [ThemeManager] Loaded \(themes.count) themes (including marketplace themes)")
    }
    
    // MARK: - Marketplace Themes Integration
    
    private func createMarketplaceThemes() -> [AppTheme] {
        return [
            // July 4th Theme
            AppTheme(
                id: "independence_day_theme_2024",
                name: "Freedom Feast",
                description: "Celebrate America with patriotic red, white, and blue colors plus victory fireworks!",
                isPremium: true,
                seasonStart: "06-01",
                seasonEnd: "08-31",
                plateStyle: AppTheme.PlateStyle(
                    background: "stars_field",
                    borderColor: "#8B0000", // Patriotic Red
                    plateColor: "#FFFFFF"   // Pure White
                ),
                foodIcons: AppTheme.FoodIcons(
                    protein: "turkey",
                    carbs: "potato",
                    fats: "butter"
                ),
                colors: AppTheme.ThemeColors(
                    primary: "#CC0000",    // Patriotic Red
                    secondary: "#1A237E",  // Freedom Blue
                    accent: "#FFFFFF",     // Pure White
                    background: "#F8F9FA"
                ),
                specialEffects: AppTheme.SpecialEffects(
                    particles: "fireworks",
                    celebrationAnimation: "star_sparkles",
                    overfillEffect: "flag_wave"
                )
            ),
            
            // Pride Theme
            AppTheme(
                id: "pride_theme_2024",
                name: "Rainbow Celebration",
                description: "Celebrate diversity with vibrant rainbow colors and inclusive sparkles",
                isPremium: true,
                seasonStart: "06-01",
                seasonEnd: "06-30",
                plateStyle: AppTheme.PlateStyle(
                    background: "rainbow_gradient",
                    borderColor: "#FF0000", // Rainbow Red
                    plateColor: "#FFFFFF"   // Pure White
                ),
                foodIcons: AppTheme.FoodIcons(
                    protein: "turkey",
                    carbs: "potato",
                    fats: "butter"
                ),
                colors: AppTheme.ThemeColors(
                    primary: "#FF0000",    // Rainbow Red
                    secondary: "#FF8C00",  // Rainbow Orange
                    accent: "#FFFF00",     // Rainbow Yellow
                    background: "#F8F9FA"
                ),
                specialEffects: AppTheme.SpecialEffects(
                    particles: "rainbow_sparkles",
                    celebrationAnimation: "rainbow_burst",
                    overfillEffect: nil
                )
            ),
            
            // Summer Beach Theme
            AppTheme(
                id: "summer_beach_theme_2024",
                name: "Summer Beach",
                description: "Feel the ocean breeze with beach colors and tropical vibes",
                isPremium: true,
                seasonStart: "06-01",
                seasonEnd: "08-31",
                plateStyle: AppTheme.PlateStyle(
                    background: "ocean_waves",
                    borderColor: "#3366CC", // Ocean Blue
                    plateColor: "#F5F5DC"   // Sand Beige
                ),
                foodIcons: AppTheme.FoodIcons(
                    protein: "turkey",
                    carbs: "potato",
                    fats: "butter"
                ),
                colors: AppTheme.ThemeColors(
                    primary: "#3366CC",    // Ocean Blue
                    secondary: "#E6D7A7",  // Sand Beige
                    accent: "#FF8C42",     // Sunset Orange
                    background: "#F0F8FF"
                ),
                specialEffects: AppTheme.SpecialEffects(
                    particles: "ocean_waves",
                    celebrationAnimation: "beach_ball_bounce",
                    overfillEffect: "seagull_flight"
                )
            ),
            
            // Hanukkah Theme
            AppTheme(
                id: "hanukkah_theme_2024",
                name: "Festival of Lights",
                description: "Celebrate Hanukkah with the warm glow of the menorah",
                isPremium: true,
                seasonStart: "12-01",
                seasonEnd: "12-31",
                plateStyle: AppTheme.PlateStyle(
                    background: "dreidels",
                    borderColor: "#0066CC", // Hanukkah Blue
                    plateColor: "#FFFFFF"   // Pure White
                ),
                foodIcons: AppTheme.FoodIcons(
                    protein: "turkey",
                    carbs: "potato",
                    fats: "butter"
                ),
                colors: AppTheme.ThemeColors(
                    primary: "#0066CC",    // Hanukkah Blue
                    secondary: "#C0C0C0",  // Silver
                    accent: "#FFFFFF",     // White
                    background: "#F8F8FF"
                ),
                specialEffects: AppTheme.SpecialEffects(
                    particles: "candle_flicker",
                    celebrationAnimation: "dreidel_spin",
                    overfillEffect: nil
                )
            ),
            
            // Yule Theme
            AppTheme(
                id: "yule_theme_2024",
                name: "Yule",
                description: "Celebrate the longest night with Yule traditions",
                isPremium: true,
                seasonStart: "12-01",
                seasonEnd: "12-31",
                plateStyle: AppTheme.PlateStyle(
                    background: "evergreen",
                    borderColor: "#1A4B8C", // Deep Winter Blue
                    plateColor: "#FFFFFF"   // Pure White
                ),
                foodIcons: AppTheme.FoodIcons(
                    protein: "turkey",
                    carbs: "potato",
                    fats: "butter"
                ),
                colors: AppTheme.ThemeColors(
                    primary: "#1A4B8C",    // Deep Winter Blue
                    secondary: "#CC9966",   // Warm Wood
                    accent: "#FFF2E6",      // Candle Light
                    background: "#F8F9FA"
                ),
                specialEffects: AppTheme.SpecialEffects(
                    particles: "log_burning",
                    celebrationAnimation: "solstice_light",
                    overfillEffect: nil
                )
            ),
            
            // Halloween Theme
            AppTheme(
                id: "halloween_theme_2024",
                name: "Spooky Treats",
                description: "Halloween magic with pumpkin oranges and spooky purples",
                isPremium: true,
                seasonStart: "10-01",
                seasonEnd: "11-30",
                plateStyle: AppTheme.PlateStyle(
                    background: "spider_webs",
                    borderColor: "#FF6600", // Pumpkin Orange
                    plateColor: "#2D1B69"   // Spooky Purple
                ),
                foodIcons: AppTheme.FoodIcons(
                    protein: "turkey",
                    carbs: "potato",
                    fats: "butter"
                ),
                colors: AppTheme.ThemeColors(
                    primary: "#FF6600",    // Pumpkin Orange
                    secondary: "#2D1B69",  // Spooky Purple
                    accent: "#000000",     // Halloween Black
                    background: "#1A1A1A"
                ),
                specialEffects: AppTheme.SpecialEffects(
                    particles: "floating_ghosts",
                    celebrationAnimation: "pumpkin_glow",
                    overfillEffect: nil
                )
            ),
            
            // Valentine's Theme
            AppTheme(
                id: "valentines_theme_2024",
                name: "Love Bites",
                description: "Romance your nutrition with passionate pinks and love-filled hearts",
                isPremium: true,
                seasonStart: "02-01",
                seasonEnd: "02-28",
                plateStyle: AppTheme.PlateStyle(
                    background: "floating_hearts",
                    borderColor: "#E91E63", // Romantic Pink
                    plateColor: "#FCE4EC"   // Soft Pink
                ),
                foodIcons: AppTheme.FoodIcons(
                    protein: "turkey",
                    carbs: "potato",
                    fats: "butter"
                ),
                colors: AppTheme.ThemeColors(
                    primary: "#E91E63",    // Romantic Pink
                    secondary: "#AD1457",  // Deep Rose
                    accent: "#F8BBD9",     // Soft Pink
                    background: "#FFF0F5"
                ),
                specialEffects: AppTheme.SpecialEffects(
                    particles: "heart_sparkles",
                    celebrationAnimation: "cupid_arrows",
                    overfillEffect: nil
                )
            ),
            
            // St. Patrick's Theme
            AppTheme(
                id: "stpatricks_theme_2024",
                name: "Lucky Greens",
                description: "Find your pot of nutritional gold with Irish greens and shamrock magic",
                isPremium: true,
                seasonStart: "03-01",
                seasonEnd: "03-31",
                plateStyle: AppTheme.PlateStyle(
                    background: "four_leaf_clovers",
                    borderColor: "#2E7D32", // Irish Green
                    plateColor: "#E8F5E8"   // Light Green
                ),
                foodIcons: AppTheme.FoodIcons(
                    protein: "turkey",
                    carbs: "potato",
                    fats: "butter"
                ),
                colors: AppTheme.ThemeColors(
                    primary: "#2E7D32",    // Irish Green
                    secondary: "#1B5E20",  // Forest Green
                    accent: "#FFD700",     // Pot of Gold
                    background: "#F1F8E9"
                ),
                specialEffects: AppTheme.SpecialEffects(
                    particles: "rainbow_sparkles",
                    celebrationAnimation: "dancing_leprechauns",
                    overfillEffect: nil
                )
            )
        ]
    }
    
    private func loadTheme(from fileName: String) -> AppTheme? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let theme = try? JSONDecoder().decode(AppTheme.self, from: data) else {
            print("❌ [ThemeManager] Failed to load theme: \(fileName)")
            return nil
        }
        
        return theme
    }
    
    // MARK: - Theme Selection
    
    func selectTheme(_ theme: AppTheme) {
        self.currentTheme = theme
        saveTheme()
        print("✅ [ThemeManager] Selected theme: \(theme.name)")
    }
    
    private func saveTheme() {
        if let encoded = try? JSONEncoder().encode(currentTheme) {
            userDefaults.set(encoded, forKey: currentThemeKey)
        }
    }
    
    private func loadSavedTheme() {
        guard let data = userDefaults.data(forKey: currentThemeKey),
              let theme = try? JSONDecoder().decode(AppTheme.self, from: data) else {
            return
        }
        
        self.currentTheme = theme
    }
    
    // MARK: - Seasonal Theme Logic
    
    private func checkSeasonalThemes() {
        let currentDate = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        let currentDateString = formatter.string(from: currentDate)
        
        print("🎃 [ThemeManager] Checking seasonal themes on date: \(currentDateString)")
        
        // Check if any seasonal theme should be active
        for theme in availableThemes {
            if let seasonStart = theme.seasonStart,
               let seasonEnd = theme.seasonEnd {
                print("🎃 [ThemeManager] Checking theme \(theme.name): \(seasonStart) to \(seasonEnd)")
                if isDateInSeason(currentDateString, start: seasonStart, end: seasonEnd) {
                    print("🎃 [ThemeManager] Theme \(theme.name) is in season!")
                    if !theme.isPremium || StoreKitManager.shared.isPremium {
                        suggestSeasonalTheme(theme)
                    } else {
                        print("🎃 [ThemeManager] Theme \(theme.name) requires premium")
                    }
                    break
                }
            }
        }
    }
    
    private func isDateInSeason(_ date: String, start: String, end: String) -> Bool {
        // Convert MM-dd strings to comparable values
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        
        guard let startDate = dateFormatter.date(from: start),
              let endDate = dateFormatter.date(from: end),
              let currentDate = dateFormatter.date(from: date) else {
            print("🎃 [ThemeManager] Error parsing dates: \(date), \(start), \(end)")
            return false
        }
        
        // Create comparable date strings for the current year
        let currentYear = Calendar.current.component(.year, from: Date())
        let calendar = Calendar.current
        
        guard let startDateThisYear = calendar.date(from: DateComponents(year: currentYear, month: calendar.component(.month, from: startDate), day: calendar.component(.day, from: startDate))),
              let endDateThisYear = calendar.date(from: DateComponents(year: currentYear, month: calendar.component(.month, from: endDate), day: calendar.component(.day, from: endDate))),
              let currentDateThisYear = calendar.date(from: DateComponents(year: currentYear, month: calendar.component(.month, from: currentDate), day: calendar.component(.day, from: currentDate))) else {
            print("🎃 [ThemeManager] Error creating date components")
            return false
        }
        
        let isInSeason = currentDateThisYear >= startDateThisYear && currentDateThisYear <= endDateThisYear
        print("🎃 [ThemeManager] Date comparison: \(currentDateThisYear) >= \(startDateThisYear) && \(currentDateThisYear) <= \(endDateThisYear) = \(isInSeason)")
        return isInSeason
    }
    
    private func suggestSeasonalTheme(_ theme: AppTheme) {
        // Only suggest if not already using this theme
        guard currentTheme.id != theme.id else { return }
        
        isSeasonalThemeActive = true
        print("🎃 [ThemeManager] Seasonal theme available: \(theme.name)")
        
        // Auto-apply if user has premium
        if StoreKitManager.shared.isPremium {
            selectTheme(theme)
        }
    }
    
    // MARK: - Theme Access
    
    func getAvailableThemes(isPremium: Bool) -> [AppTheme] {
        if isPremium {
            return availableThemes
        } else {
            return availableThemes.filter { !$0.isPremium }
        }
    }
    
    // MARK: - Theme Properties
    
    // Trigger celebration effects
    func triggerCelebration() {
        if let effects = currentTheme.specialEffects,
           let celebrationType = effects.celebrationAnimation {
            print("🎉 [ThemeManager] Triggering celebration: \(celebrationType)")
            // Post notification to trigger SpecialEffectsView
            NotificationCenter.default.post(name: .triggerCelebration, object: nil)
        } else {
            print("🎉 [ThemeManager] No special effects found, triggering default celebration")
            // Post notification even if no special effects (for testing)
            NotificationCenter.default.post(name: .triggerCelebration, object: nil)
        }
    }
    
    var primaryColor: Color {
        Color(hex: currentTheme.colors.primary) ?? .blue
    }
    
    var secondaryColor: Color {
        Color(hex: currentTheme.colors.secondary) ?? .purple
    }
    
    var accentColor: Color {
        Color(hex: currentTheme.colors.accent) ?? .orange
    }
    
    var backgroundColor: Color {
        Color(hex: currentTheme.colors.background) ?? .gray
    }
    
    var plateBorderColor: Color {
        Color(hex: currentTheme.plateStyle.borderColor) ?? .gray
    }
    
    var plateColor: Color {
        Color(hex: currentTheme.plateStyle.plateColor) ?? .white
    }
    
    // Food icon names for current theme
    var proteinIcon: String { currentTheme.foodIcons.protein }
    var carbsIcon: String { currentTheme.foodIcons.carbs }
    var fatsIcon: String { currentTheme.foodIcons.fats }
}

// MARK: - Extensions

extension ThemeManager {
    static let shared = ThemeManager()
    
    static var preview: ThemeManager {
        let manager = ThemeManager()
        return manager
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

