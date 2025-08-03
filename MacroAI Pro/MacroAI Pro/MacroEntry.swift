// MacroEntry.swift
// SwiftData model for persistent macro entry storage
import Foundation
import SwiftData

enum MacroEntrySource: String, Codable, CaseIterable {
    case manual = "manual"
    case photo = "photo"
    case recipe = "recipe"
    case spoonacular = "spoonacular"
    
    var displayName: String {
        switch self {
        case .manual: return "Manual Entry"
        case .photo: return "Photo Scan"
        case .recipe: return "Recipe"
        case .spoonacular: return "Food Database"
        }
    }
    
    var icon: String {
        switch self {
        case .manual: return "pencil"
        case .photo: return "camera"
        case .recipe: return "book.closed"
        case .spoonacular: return "magnifyingglass"
        }
    }
}

// MARK: - Serving Size Types
enum ServingSizeType: String, Codable, CaseIterable {
    case grams = "grams"
    case ounces = "ounces"
    case cups = "cups"
    case tablespoons = "tablespoons"
    case teaspoons = "teaspoons"
    case pieces = "pieces"
    case slices = "slices"
    case whole = "whole"
    
    var displayName: String {
        switch self {
        case .grams: return "grams"
        case .ounces: return "ounces"
        case .cups: return "cups"
        case .tablespoons: return "tbsp"
        case .teaspoons: return "tsp"
        case .pieces: return "pieces"
        case .slices: return "slices"
        case .whole: return "whole"
        }
    }
    
    var abbreviation: String {
        switch self {
        case .grams: return "g"
        case .ounces: return "oz"
        case .cups: return "cup"
        case .tablespoons: return "tbsp"
        case .teaspoons: return "tsp"
        case .pieces: return "pc"
        case .slices: return "slice"
        case .whole: return "whole"
        }
    }
}

@Model
class MacroEntry {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var foodName: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
    var imageData: Data?
    var source: MacroEntrySource
    
    // MARK: - Serving Size Properties
    var servingSize: Double
    var servingSizeType: ServingSizeType
    var baseServingSize: Double // The serving size that the nutrition data is based on
    var baseServingSizeType: ServingSizeType
    
    // Computed properties for convenience
    var totalMacros: Int {
        protein + carbs + fats
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var dayOfEntry: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: timestamp)
    }
    
    // New computed property for name with source indication
    var name: String {
        return foodName
    }
    
    // MARK: - Serving Size Display
    var servingSizeDisplay: String {
        if servingSize == 1.0 && servingSizeType == .whole {
            return "1 whole"
        } else if servingSize == 1.0 {
            return "1 \(servingSizeType.displayName)"
        } else {
            return "\(String(format: "%.1f", servingSize)) \(servingSizeType.displayName)"
        }
    }
    
    var baseServingSizeDisplay: String {
        if baseServingSize == 1.0 && baseServingSizeType == .whole {
            return "1 whole"
        } else if baseServingSize == 1.0 {
            return "1 \(baseServingSizeType.displayName)"
        } else {
            return "\(String(format: "%.1f", baseServingSize)) \(baseServingSizeType.displayName)"
        }
    }
    
    // MARK: - Nutrition Multiplier
    var nutritionMultiplier: Double {
        guard baseServingSize > 0 else { return 1.0 }
        return servingSize / baseServingSize
    }
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        name: String = "",
        calories: Int = 0,
        protein: Int = 0,
        carbs: Int = 0,
        fats: Int = 0,
        imageData: Data? = nil,
        source: MacroEntrySource = .manual,
        servingSize: Double = 1.0,
        servingSizeType: ServingSizeType = .whole,
        baseServingSize: Double = 1.0,
        baseServingSizeType: ServingSizeType = .whole
    ) {
        self.id = id
        self.timestamp = timestamp
        self.foodName = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.imageData = imageData
        self.source = source
        self.servingSize = servingSize
        self.servingSizeType = servingSizeType
        self.baseServingSize = baseServingSize
        self.baseServingSizeType = baseServingSizeType
    }
}

// MARK: - Sample Data for Previews
extension MacroEntry {
    static let sampleEntries: [MacroEntry] = [
        MacroEntry(
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            name: "Grilled Chicken Breast",
            calories: 231,
            protein: 43,
            carbs: 0,
            fats: 5,
            source: .manual,
            servingSize: 1.0,
            servingSizeType: .whole,
            baseServingSize: 1.0,
            baseServingSizeType: .whole
        ),
        MacroEntry(
            timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
            name: "Brown Rice Bowl",
            calories: 216,
            protein: 5,
            carbs: 45,
            fats: 2,
            source: .photo,
            servingSize: 1.0,
            servingSizeType: .whole,
            baseServingSize: 1.0,
            baseServingSizeType: .whole
        ),
        MacroEntry(
            timestamp: Date().addingTimeInterval(-14400), // 4 hours ago
            name: "Mixed Berry Smoothie",
            calories: 180,
            protein: 6,
            carbs: 35,
            fats: 3,
            source: .recipe,
            servingSize: 1.0,
            servingSizeType: .whole,
            baseServingSize: 1.0,
            baseServingSizeType: .whole
        )
    ]
} 