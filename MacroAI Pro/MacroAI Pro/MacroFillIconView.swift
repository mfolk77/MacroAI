// MacroFillIconView.swift
// Animated macro nutrient icon with fill effects
import SwiftUI

private struct FillOverlayView: View {
    let imageName: String
    let animatedPercentage: Double
    let gradientColors: [Color]
    let fillOpacity: Double
    let isOverfilled: Bool
    var body: some View {
        Group {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(
                            height: geometry.size.height * (animatedPercentage / 100.0)
                        )
                        .opacity(fillOpacity)
                        .blendMode(isOverfilled ? .multiply : .overlay)
                }
            }
        }
        .modifier(
            (UIImage(named: imageName) != nil)
                ? AnyViewModifier { content in
                    AnyView(
                        content.mask(
                            Image(imageName)
                        .renderingMode(.original)
                                .resizable()
                                .scaledToFit()
                        )
                    )
                }
            : AnyViewModifier { content in
                    AnyView(
                        content.clipShape(RoundedRectangle(cornerRadius: 8))
                    )
                }
        )
    }
}

struct MacroFillIconView: View {
    let imageName: String
    let percentage: Double
    let fillColor: Color
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var animatedPercentage: Double = 0
    @StateObject private var themeManager = ThemeManager.shared
    
    private var isOverfilled: Bool {
        percentage > 100
    }
    
    private var displayPercentage: Double {
        min(percentage, 200) // Cap at 200% for visual purposes
    }
    
    private var finalFillColor: Color {
        if isOverfilled {
            return .black
        }
        return fillColor
    }
    
    private var overfillIntensity: Double {
        guard isOverfilled else { return 0 }
        let overfillAmount: Double = percentage - 100
        let percentOver: Double = overfillAmount / 100
        let clamped: Double
        if percentOver < 1.0 {
            clamped = percentOver
        } else {
            clamped = 1.0
        }
        return clamped
    }
    
    var body: some View {
        ZStack {
            // Base food image with fallback support
            Group {
                if UIImage(named: imageName) != nil {
                    Image(imageName)
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                } else {
                    // Fallback if image asset is missing
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            Text(fallbackText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .overlay(
                FillOverlayView(
                    imageName: imageName,
                    animatedPercentage: animatedPercentage,
                    gradientColors: gradientColors,
                    fillOpacity: fillOpacity,
                    isOverfilled: isOverfilled
                )
            )
            .overlay(
                // Overfill effects
                Group {
                    if isOverfilled {
                        // Burn/char effect
                        Image(imageName)
                        .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .colorMultiply(.black)
                            .opacity(0.6 + overfillIntensity * 0.4)
                            .scaleEffect(1.0 + overfillIntensity * 0.05)
                        
                        // Pulsing glow for severe overfill
                        if overfillIntensity > 0.5 {
                            Image(imageName)
                        .renderingMode(.original)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.red)
                                .opacity(0.3)
                                .scaleEffect(1.1)
                                .blur(radius: 3)
                                .animation(
                                    .easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true),
                                    value: overfillIntensity
                                )
                        }
                    }
                }
            )
        }
        .onChange(of: percentage) { oldValue, newValue in
            // Only animate if change is significant (avoid micro-animations)
            if abs(newValue - oldValue) > 0.5 {
                withAnimation(.easeInOut(duration: 1.2)) {
                    animatedPercentage = min(newValue, 100)
                }
            } else {
                animatedPercentage = min(newValue, 100)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animatedPercentage = min(percentage, 100)
            }
        }
        .accessibilityLabel(accessibilityDescription)
    }
    
    // MARK: - Computed Properties
    
    private var gradientColors: [Color] {
        if isOverfilled {
            return [
                .black.opacity(0.8),
                .black.opacity(0.6),
                .black.opacity(0.4)
            ]
        }
        
        // Adjust colors for dark mode
        let baseColor = finalFillColor
        let lighterColor = baseColor.opacity(0.7)
        let darkerColor = colorScheme == .dark ? 
            baseColor.opacity(0.9) : 
            baseColor.opacity(0.8)
        
        return [darkerColor, baseColor, lighterColor]
    }
    
    private var fillOpacity: Double {
        if isOverfilled {
            return 0.8 + overfillIntensity * 0.2
        }
        
        // Ensure visibility in both light and dark modes
        return colorScheme == .dark ? 0.8 : 0.6
    }
    
    private var fallbackText: String {
        switch imageName.lowercased() {
        case "butter":
            return "🧈 Fats"
        case "turkey":
            return "🍗 Protein"
        case "potato":
            return "🥔 Carbs"
        default:
            return "📊 Macro"
        }
    }
    
    private var accessibilityDescription: String {
        let percentText = String(format: "%.0f", percentage)
        let status = isOverfilled ? "overfilled" : "filled"
        
        switch imageName.lowercased() {
        case "butter":
            return "Fats \(percentText) percent \(status)"
        case "turkey":
            return "Protein \(percentText) percent \(status)"
        case "potato":
            return "Carbs \(percentText) percent \(status)"
        default:
            return "Macro \(percentText) percent \(status)"
        }
    }
}

// MARK: - Convenience Initializers

extension MacroFillIconView {
    /// Create a protein icon with red fill color
    static func protein(percentage: Double) -> MacroFillIconView {
        MacroFillIconView(
            imageName: "turkey",
            percentage: percentage,
            fillColor: .red
        )
    }
    
    /// Create a fats icon with yellow fill color
    static func fats(percentage: Double) -> MacroFillIconView {
        MacroFillIconView(
            imageName: "butter",
            percentage: percentage,
            fillColor: .yellow
        )
    }
    
    /// Create a carbs icon with green fill color
    static func carbs(percentage: Double) -> MacroFillIconView {
        MacroFillIconView(
            imageName: "potato",
            percentage: percentage,
            fillColor: .green
        )
    }
}

// MARK: - Preview

#Preview("Normal Fill") {
    HStack(spacing: 20) {
        VStack {
            MacroFillIconView.protein(percentage: 75)
                .frame(width: 150, height: 150)
            Text("75% Protein")
                .font(.caption)
        }
        
        VStack {
            MacroFillIconView.fats(percentage: 45)
                .frame(width: 100, height: 100)
            Text("45% Fats")
                .font(.caption)
        }
        
        VStack {
            MacroFillIconView.carbs(percentage: 90)
                .frame(width: 100, height: 100)
            Text("90% Carbs")
                .font(.caption)
        }
    }
    .padding()
}

#Preview("Overfilled") {
    HStack(spacing: 20) {
        VStack {
            MacroFillIconView.protein(percentage: 120)
                .frame(width: 100, height: 100)
            Text("120% Protein")
                .font(.caption)
        }
        
        VStack {
            MacroFillIconView.fats(percentage: 150)
                .frame(width: 100, height: 100)
            Text("150% Fats")
                .font(.caption)
        }
        
        VStack {
            MacroFillIconView.carbs(percentage: 180)
                .frame(width: 100, height: 100)
            Text("180% Carbs")
                .font(.caption)
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    HStack(spacing: 20) {
        VStack {
            MacroFillIconView.protein(percentage: 85)
                .frame(width: 100, height: 100)
            Text("85% Protein")
                .font(.caption)
        }
        
        VStack {
            MacroFillIconView.fats(percentage: 115)
                .frame(width: 100, height: 100)
            Text("115% Fats")
                .font(.caption)
        }
        
        VStack {
            MacroFillIconView.carbs(percentage: 60)
                .frame(width: 100, height: 100)
            Text("60% Carbs")
                .font(.caption)
        }
    }
    .padding()
    .preferredColorScheme(.dark)
} 

struct AnyViewModifier: ViewModifier {
    let modifier: (AnyView) -> AnyView

    func body(content: Content) -> some View {
        modifier(AnyView(content))
    }
}
