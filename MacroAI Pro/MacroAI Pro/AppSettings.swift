import SwiftUI
internal import Combine

/// Enum for color scheme options
public enum AppColorScheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system
    public var id: String { rawValue }
}

/// Enum for text size options
public enum TextSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    public var id: String { rawValue }
}

/// Observable settings model for SettingsView
@MainActor
final class AppSettings: ObservableObject {
    private let colorSchemeKey = "colorScheme"
    private let textSizeKey = "textSize"
    private let highContrastKey = "highContrast"
    private let reduceMotionKey = "reduceMotion"
    
    private let defaults = UserDefaults.standard
    
    @Published public var colorScheme: AppColorScheme {
        didSet {
            defaults.set(colorScheme.rawValue, forKey: colorSchemeKey)
        }
    }
    @Published public var textSize: TextSize {
        didSet {
            defaults.set(textSize.rawValue, forKey: textSizeKey)
        }
    }
    @Published public var highContrast: Bool {
        didSet {
            defaults.set(highContrast, forKey: highContrastKey)
        }
    }
    @Published public var reduceMotion: Bool {
        didSet {
            defaults.set(reduceMotion, forKey: reduceMotionKey)
        }
    }
    
    init() {
        let colorSchemeRaw = defaults.string(forKey: colorSchemeKey) ?? AppColorScheme.system.rawValue
        colorScheme = AppColorScheme(rawValue: colorSchemeRaw) ?? .system
        let textSizeRaw = defaults.string(forKey: textSizeKey) ?? TextSize.medium.rawValue
        textSize = TextSize(rawValue: textSizeRaw) ?? .medium
        highContrast = defaults.bool(forKey: highContrastKey)
        reduceMotion = defaults.bool(forKey: reduceMotionKey)
    }
}
