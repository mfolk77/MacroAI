import SwiftUI

struct PremiumDancingTree: View {
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    @State private var sunglassesBounce: CGFloat = 0
    @State private var starGlow: Bool = false
    @State private var ornamentShimmer: Bool = false
    @State private var shadowOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background matching original
            backgroundLayer
                .zIndex(1) // Background layer
            
            // Main tree with layered effects
            ZStack {
                // Shadow layer
                treeImageLayer
                    .opacity(0.3)
                    .blur(radius: 8)
                    .offset(x: 4, y: 8 + shadowOffset)
                    .scaleEffect(0.98)
                    .zIndex(2) // Shadow layer
                
                // Main tree image
                treeImageLayer
                    .scaleEffect(scaleEffect)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: scaleEffect)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: rotationAngle)
                    .zIndex(99999) // ABSOLUTE FRONT - MAIN TREE
                
                // Overlay effects
                overlayEffects
                    .scaleEffect(scaleEffect)
                    .rotationEffect(.degrees(rotationAngle))
                    .zIndex(99999) // ABSOLUTE FRONT - EFFECTS
                
                // Particle effects
                particleLayer
                    .zIndex(99999) // ABSOLUTE FRONT - PARTICLES
            }
            .zIndex(99999) // ABSOLUTE FRONT - ENTIRE TREE SYSTEM
        }
        .zIndex(99999) // ABSOLUTE FRONT - ENTIRE COMPONENT
        .onAppear {
            startDancing()
        }
    }
    
    private var backgroundLayer: some View {
        ZStack {
            // Recreate the blue gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.3, blue: 0.5),
                    Color(red: 0.3, green: 0.4, blue: 0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Snow particles
            ForEach(0..<30, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.3...0.8)))
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        Animation.linear(duration: Double.random(in: 4...8))
                            .repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
            }
        }
    }
    
    private var treeImageLayer: some View {
        // Use the actual Christmas tree image from assets
        Image("Image")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 300, maxHeight: 300) // Smaller, more manageable size
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var overlayEffects: some View {
        ZStack {
            // Star glow effect REMOVED - unwanted decoration
            // Ornament shimmer effects REMOVED - unwanted decorations
            // Sunglasses bounce effect REMOVED - unwanted decoration
        }
    }
    
    private var particleLayer: some View {
        ZStack {
            // Sparkle effects REMOVED - unwanted decorations
        }
    }
    

    
    private func startDancing() {
        // Main bounce animation
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            scaleEffect = 1.05
        }
        
        // Subtle rotation sway
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            rotationAngle = 2.0
        }
        
        // Star glow
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            starGlow = true
        }
        
        // Ornament shimmer
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            ornamentShimmer = true
        }
        
        // Sunglasses bounce
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            sunglassesBounce = -3
        }
        
        // Shadow movement
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            shadowOffset = 2
        }
    }
}

// MARK: - Usage Examples
struct TreeImplementationExample: View {
    var body: some View {
        VStack {
            PremiumDancingTree()
                .frame(height: 400)
            
            Text("🎄 Premium Dancing Tree Animation")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
    }
}

#Preview {
    TreeImplementationExample()
} 