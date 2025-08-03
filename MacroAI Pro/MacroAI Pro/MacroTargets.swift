// MacroTargets.swift
// Centralized macro target configuration
import Foundation

struct MacroTargets {
    let protein: Double
    let fats: Double
    let carbs: Double
    
    // MARK: - Default Configurations
    
    static let moderate = MacroTargets(protein: 150, fats: 65, carbs: 200)
    static let highProtein = MacroTargets(protein: 180, fats: 60, carbs: 180)
    static let lowCarb = MacroTargets(protein: 120, fats: 80, carbs: 100)
    static let balanced = MacroTargets(protein: 130, fats: 70, carbs: 220)
    
    // MARK: - User Defaults Storage
    
    private static let proteinKey = "macro_target_protein"
    private static let fatsKey = "macro_target_fats"
    private static let carbsKey = "macro_target_carbs"
    
    /// Get user's saved macro targets, or default to moderate
    static var current: MacroTargets {
        let defaults = UserDefaults.standard
        
        // Check if user has saved custom targets
        if defaults.object(forKey: proteinKey) != nil {
            let protein = max(defaults.double(forKey: proteinKey), 1.0) // Ensure minimum 1g
            let fats = max(defaults.double(forKey: fatsKey), 1.0) // Ensure minimum 1g
            let carbs = max(defaults.double(forKey: carbsKey), 1.0) // Ensure minimum 1g
            
            return MacroTargets(
                protein: protein,
                fats: fats,
                carbs: carbs
            )
        }
        
        return .moderate
    }
    
    /// Save current targets as user's preference
    func save() {
        let defaults = UserDefaults.standard
        
        // Ensure we never save zero or negative values
        let safeProtein = max(protein, 1.0)
        let safeFats = max(fats, 1.0)
        let safeCarbs = max(carbs, 1.0)
        
        defaults.set(safeProtein, forKey: Self.proteinKey)
        defaults.set(safeFats, forKey: Self.fatsKey)
        defaults.set(safeCarbs, forKey: Self.carbsKey)
    }
    
    /// Reset to moderate defaults
    static func resetToDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: proteinKey)
        defaults.removeObject(forKey: fatsKey)
        defaults.removeObject(forKey: carbsKey)
    }
    
    // MARK: - Convenience Properties
    
    /// Total daily calorie estimate (rough calculation)
    var estimatedCalories: Int {
        Int((protein * 4) + (fats * 9) + (carbs * 4))
    }
    
    /// Formatted display string
    var displayString: String {
        "\(Int(protein))P/\(Int(fats))F/\(Int(carbs))C"
    }
    
    /// Calculate percentage for a given macro value
    func proteinPercentage(for current: Double) -> Double {
        protein > 0 ? (current / protein) * 100 : 0
    }
    
    func fatsPercentage(for current: Double) -> Double {
        fats > 0 ? (current / fats) * 100 : 0
    }
    
    func carbsPercentage(for current: Double) -> Double {
        carbs > 0 ? (current / carbs) * 100 : 0
    }
    
    // MARK: - Validation
    
    /// Check if targets are within reasonable ranges
    var isValid: Bool {
        protein >= 50 && protein <= 300 &&
        fats >= 20 && fats <= 150 &&
        carbs >= 50 && carbs <= 500
    }
    
    /// Validated version with clamped values
    var validated: MacroTargets {
        MacroTargets(
            protein: max(50, min(300, protein)),
            fats: max(20, min(150, fats)),
            carbs: max(50, min(500, carbs))
        )
    }
} 