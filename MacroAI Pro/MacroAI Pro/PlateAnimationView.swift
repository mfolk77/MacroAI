import SwiftUI

struct PlateAnimationView: View {
    @State private var proteinProgress: Double = 0 // 0...1
    @State private var fatProgress: Double = 0
    @State private var carbProgress: Double = 0
    @State private var showCelebration = false
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Plate background
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(Color(.systemGray5), lineWidth: size * 0.04))
                    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.12), radius: size * 0.06)
                    .frame(width: size * 0.9, height: size * 0.9)
                    .position(x: geo.size.width/2, y: geo.size.height/2)
                
                // Center label
                Text("Today’s Macros")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                    .shadow(color: Color(.systemGray3), radius: 3, x: 0, y: 1)
                    .position(x: geo.size.width/2, y: geo.size.height/4 - size * 0.48)
                
                // Fats (Top)
                VStack(spacing: 4) {
                    Image("butter")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.23, height: size * 0.23)
                        .animation(.easeInOut(duration: 1.0), value: fatProgress)
                    Text("Fats")
                        .font(.caption2)
                        .foregroundColor(.black)
                    Text("\(Int(fatProgress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .transition(.opacity)
                        .animation(.easeInOut, value: fatProgress)
                }
                .position(x: geo.size.width/2, y: geo.size.height/2 - size * 0.31)
                
                // Protein (Bottom Left)
                VStack(spacing: 2) {
                    Image("turkey")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.5, height: size * 0.5)
                        .animation(.easeInOut(duration: 1.0), value: proteinProgress)
                    VStack(spacing: 0) {
                        Text("Protein")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Text("\(Int(proteinProgress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .transition(.opacity)
                            .animation(.easeInOut, value: proteinProgress)
                    }
                    .offset(y: -size * 0.15)
                }
                .position(x: geo.size.width/2 - size * 0.26, y: geo.size.height/2 + size * 0.18)
                
                // Carbs (Bottom Right)
                VStack(spacing: 4) {
                    Image("potato")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.23, height: size * 0.23)
                        .animation(.easeInOut(duration: 1.0), value: carbProgress)
                    Text("Carbs")
                        .font(.caption2)
                        .foregroundColor(.black)
                    Text("\(Int(carbProgress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .transition(.opacity)
                        .animation(.easeInOut, value: carbProgress)
                }
                .position(x: geo.size.width/2 + size * 0.26, y: geo.size.height/2 + size * 0.18)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                withAnimation { proteinProgress = 1 }
                withAnimation { fatProgress = 1 }
                withAnimation { carbProgress = 1 }
                
                // Trigger celebration when all macros are complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showCelebration = true
                    
                    // Trigger celebration effects
                    if let effects = themeManager.currentTheme.specialEffects {
                        if effects.celebrationAnimation != nil {
                            // Celebration will be handled by SpecialEffectsView
                        }
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    PlateAnimationView()
}
