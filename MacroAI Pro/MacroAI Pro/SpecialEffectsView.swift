import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var type: String
    var color: Color
    var scale: CGFloat
    var rotation: Double
    var animation: Animation
}

struct SpecialEffectsView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var particles: [Particle] = []
    @Binding var celebrationActive: Bool
    @State private var overfillActive = false
    @State private var celebrationTimer: Timer?
    @State private var fullScreenCelebration = false
    @State private var celebrationType = ""
    
    // Animation states for dynamic movement
    @State private var danceOffset: CGFloat = 0
    @State private var spinRotation: Double = 0
    @State private var bounceScale: CGFloat = 1.0
    @State private var jigOffset: CGFloat = 0
    @State private var heartPulse: CGFloat = 1.0
    @State private var bunnyJump: CGFloat = 0
    
    // Rainbow colors for Pride theme
    private let rainbowColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]
    
    // Random image selection for themes with multiple images
    @State private var selectedImageIndex: Int = 0
    
    // Generate a new random index when celebration starts
    private func generateRandomImageIndex(for theme: String) {
        selectedImageIndex = getRandomImageIndex(for: theme)
        print("🎭 [SpecialEffectsView] Generated random index \(selectedImageIndex) for theme: \(theme)")
    }
    
    var body: some View {
        ZStack {
            // Dark overlay when celebration is active
            if fullScreenCelebration {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(9998) // High but below celebration
            }
            
            // Full-screen celebration overlay - MUST BE ON TOP
            if fullScreenCelebration {
                celebrationOverlay
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                    .allowsHitTesting(true)
                
                // Particles removed - too distracting
            }
        }
        .zIndex(999999) // ENSURE ENTIRE VIEW IS ON TOP
        .onReceive(NotificationCenter.default.publisher(for: .triggerCelebration)) { _ in
            print("🎭 [SpecialEffectsView] Received triggerCelebration notification")
            handleCelebrationNotification()
        }
    }
    
    // MARK: - Random Image Selection
    
    private func getRandomImageIndex(for theme: String) -> Int {
        // Return random index for themes with multiple images
        switch theme {
        case "hanukkah":
            return Int.random(in: 0...2) // 3 images available
        case "yule":
            return Int.random(in: 0...2) // 3 images available
        case "fall":
            return Int.random(in: 0...2) // 3 images available
        case "stpatricks":
            return Int.random(in: 0...2) // 3 images available
        case "spring":
            return Int.random(in: 0...1) // 2 images available
        case "winter":
            return Int.random(in: 0...1) // 2 images available
        case "fourth_july":
            return Int.random(in: 0...0) // 1 image available
        case "summer":
            return Int.random(in: 0...0) // 1 image available (will be added)
        case "easter":
            return Int.random(in: 0...2) // 3 images available
        case "halloween":
            return Int.random(in: 0...2) // 3 images available
        case "valentines":
            return Int.random(in: 0...2) // 3 images available
        case "new_year":
            return Int.random(in: 0...2) // 3 images available
        default:
            return 0
        }
    }
    
    private func getImageName(for theme: String, index: Int) -> String {
        switch theme {
        case "thanksgiving":
            return "thanksgiving_celebration"
        case "hanukkah":
            return "hanukkah_celebration"
        case "yule":
            return "yule_celebration"
        case "fall":
            return "thanksgiving_celebration"
        case "stpatricks":
            return "st_patricks_celebration"
        case "easter":
            return "easter_celebration"
        case "halloween":
            return index == 0 ? "halloween_celebration" : "halloween_celebration 1"
        case "valentines":
            return "valentines_celebration"
        case "new_year":
            return "new_year_celebration"
        case "spring":
            return "spring_celebration"
        case "winter":
            return index == 0 ? "winter_wonderland_celebration" : "winter_wonderland_celebration 1"
        case "fourth_july":
            return "july_4th_celebration"
        case "summer":
            return "summer_celebration"
        default:
            return ""
        }
    }
    
    // MARK: - Epic Celebration Overlay
    
    private var celebrationOverlay: some View {
        ZStack {
            // Spotlight background
            RadialGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.3)]),
                center: .center,
                startRadius: 50,
                endRadius: 200
            )
            .ignoresSafeArea()
            .zIndex(1) // Background layer
            
            // Theme-specific celebration
            switch celebrationType {
            case "christmas", "santa_wave":
                christmasCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "thanksgiving":
                thanksgivingCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "hanukkah":
                hanukkahCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "yule":
                yuleCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "fall":
                fallCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "stpatricks":
                stpatricksCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "easter":
                easterCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "valentines":
                valentinesCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "pride":
                prideCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "halloween":
                halloweenCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "new_year":
                newYearCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "spring":
                springCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "winter":
                winterCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "fourth_july":
                fourthJulyCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "summer":
                summerCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            case "st_patricks":
                stPatricksCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            default:
                defaultCelebration
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            }
        }
        .zIndex(999999) // ENSURE OVERLAY IS ON TOP
        .onTapGesture {
            dismissFullScreenCelebration()
        }
    }
    
    // MARK: - Christmas Celebration (Epic Tree with Sunglasses)
    
    private var christmasCelebration: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Christmas Tree with 2D image
            VStack(spacing: 20) {
                // 2D Christmas Tree View
                StylizedChristmasTreeView()
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🎉 CONGRATULATIONS! 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                

            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - St. Patrick's Celebration (Epic Irish Riverdance)
    
    private var stPatricksCelebration: some View {
        VStack(spacing: 20) {
            // Leprechaun
            ZStack {
                // Body
                VStack(spacing: 0) {
                    // Hat
                    Triangle()
                        .fill(Color.green)
                        .frame(width: 80, height: 50)
                        .offset(x: jigOffset)
                    
                    // Head
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 60, height: 60)
                        .offset(x: jigOffset)
                    
                    // Body
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 40, height: 60)
                        .offset(x: jigOffset)
                }
                .scaleEffect(bounceScale)
                .rotationEffect(.degrees(spinRotation))
                
                // Pot of Gold
                Ellipse()
                    .fill(Color.yellow)
                    .frame(width: 60, height: 30)
                    .offset(x: jigOffset + 20, y: 40)
                    .scaleEffect(bounceScale * 0.8)
            }
            .onAppear {
                startLeprechaunAnimations()
            }
            
            Text("🍀 TOP O' THE MORNIN'! 🍀")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 3, x: 0, y: 2)
        }
    }
    

    
    // MARK: - Pride Celebration (Rainbow Chipmunk)
    
    private var prideCelebration: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Pride Celebration with 2D image
            VStack(spacing: 20) {
                // 2D Pride Image View
                PrideCelebrationView()
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🎉 CONGRATULATIONS! 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                

            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    

    
    // MARK: - Thanksgiving Celebration (Turkey)
    
    private var thanksgivingCelebration: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.orange.opacity(0.8), Color.brown.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Thanksgiving Celebration with image
            VStack(spacing: 20) {
                Image("thanksgiving_celebration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🎉 CONGRATULATIONS! 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - Hanukkah Celebration (Menorah)
    
    private var hanukkahCelebration: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.yellow.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Hanukkah Celebration with random image
            VStack(spacing: 20) {
                Image("hanukkah_celebration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🎉 CONGRATULATIONS! 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - Yule Celebration (Winter Solstice)
    
    private var yuleCelebration: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.orange.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Yule Celebration with random image
            VStack(spacing: 20) {
                Image("yule_celebration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🎉 CONGRATULATIONS! 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - Fall Celebration (Autumn Harvest)
    
    private var fallCelebration: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.orange.opacity(0.8), Color.brown.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Fall Celebration with random image
            VStack(spacing: 20) {
                Image(getImageName(for: "fall", index: selectedImageIndex))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🎉 CONGRATULATIONS! 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - St. Patrick's Day Celebration (Lucky Greens)
    
    private var stpatricksCelebration: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.green.opacity(0.8), Color.orange.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // St. Patrick's Day Celebration with random image
            VStack(spacing: 20) {
                Image(getImageName(for: "stpatricks", index: selectedImageIndex))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999999) // ULTRA HIGH Z-INDEX
                
                // Congratulations text
                Text("CONGRATULATIONS!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                    .zIndex(999999999) // ULTRA HIGH Z-INDEX
            }
            .zIndex(999999999) // ULTRA HIGH Z-INDEX
        }
        .zIndex(999999999) // ULTRA HIGH Z-INDEX
    }
    
    // MARK: - Easter Celebration (Bunny)
    
    private var easterCelebration: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.pink.opacity(0.8), Color.green.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Easter Celebration with random image
            VStack(spacing: 20) {
                Image("easter_celebration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🎉 CONGRATULATIONS! 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - Valentine's Day Celebration (Hearts)
    
    private var valentinesCelebration: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.pink.opacity(0.8), Color.red.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Valentine's Day Celebration with random image
            VStack(spacing: 20) {
                Image("valentines_celebration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🎉 CONGRATULATIONS! 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - Halloween Celebration (Ghosts)
    
    private var halloweenCelebration: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.orange.opacity(0.8), Color.purple.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Halloween Celebration with random image
            VStack(spacing: 20) {
                Image(getImageName(for: "halloween", index: selectedImageIndex))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🎉 CONGRATULATIONS! 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - New Year Celebration (Fireworks)
    
    private var newYearCelebration: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.yellow.opacity(0.8), Color.blue.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // New Year Celebration with random image
            VStack(spacing: 20) {
                Image("new_year_celebration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🎉 CONGRATULATIONS! 🎉")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 3, x: 0, y: 2)
                .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - Spring Celebration
    
    private var springCelebration: some View {
        ZStack {
            // Background gradient - Cherry blossom pink to fresh green
            LinearGradient(
                colors: [Color.pink.opacity(0.8), Color.green.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Spring Celebration with random image
            VStack(spacing: 20) {
                Image(getImageName(for: "spring", index: selectedImageIndex))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🌸 CONGRATULATIONS! 🌸")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 3, x: 0, y: 2)
                .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - Winter Wonderland Celebration
    
    private var winterCelebration: some View {
        ZStack {
            // Background gradient - Frost blue to snow white
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.white.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Winter Celebration with random image
            VStack(spacing: 20) {
                Image(getImageName(for: "winter", index: selectedImageIndex))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("❄️ CONGRATULATIONS! ❄️")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 3, x: 0, y: 2)
                .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - Summer Beach Celebration
    
    private var summerCelebration: some View {
        ZStack {
            // Background gradient - Ocean blue to sand beige
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.yellow.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Summer Celebration with random image
            VStack(spacing: 20) {
                Image(getImageName(for: "summer", index: selectedImageIndex))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("🏖️ CONGRATULATIONS! 🏖️")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - Fourth of July Celebration
    
    private var fourthJulyCelebration: some View {
        ZStack {
            // Background gradient - Red, white, and blue
            LinearGradient(
                colors: [Color.red.opacity(0.8), Color.blue.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .zIndex(1)
            
            // Fourth of July Celebration with image
            VStack(spacing: 20) {
                Image(getImageName(for: "fourth_july", index: selectedImageIndex))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .scaleEffect(bounceScale)
                    .rotationEffect(.degrees(spinRotation))
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounceScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: spinRotation)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
                
                Text("CONGRATULATIONS!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                    .zIndex(999999) // SUPER HIGH Z-INDEX
            }
            .zIndex(999999) // SUPER HIGH Z-INDEX
        }
        .zIndex(999999) // SUPER HIGH Z-INDEX
    }
    
    // MARK: - Default Celebration
    
    private var defaultCelebration: some View {
        VStack(spacing: 20) {
            // Default sparkles
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                        .scaleEffect(bounceScale)
                        .offset(
                            x: CGFloat(index * 25 - 50),
                            y: CGFloat(index * 15 - 30)
                        )
                        .rotationEffect(.degrees(spinRotation))
                }
            }
            .onAppear {
                startDefaultAnimations()
            }
            
            Text("🎉 CONGRATULATIONS! 🎉")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 3, x: 0, y: 2)
        }
    }
    
    // MARK: - Particle Rendering (DISABLED)
    
    // Particles removed - too distracting and unwanted
    private func particleView(for particle: Particle) -> some View {
        EmptyView() // Return empty view instead of particles
    }
    
    // MARK: - Custom Shapes
    
    struct TreeLayer: View {
        let width: CGFloat
        let height: CGFloat
        let gradient: LinearGradient
        
        var body: some View {
            TreeLayerShape(width: width, height: height)
                .fill(gradient)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
    
    struct TreeLayerShape: Shape {
        let width: CGFloat
        let height: CGFloat
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let centerX = rect.midX
            let bottomY = rect.maxY
            let topY = rect.minY
            
            // Create a more natural tree shape
            path.move(to: CGPoint(x: centerX - width/2, y: bottomY))
            path.addLine(to: CGPoint(x: centerX - width/3, y: bottomY - height/3))
            path.addLine(to: CGPoint(x: centerX - width/4, y: bottomY - height/2))
            path.addLine(to: CGPoint(x: centerX - width/6, y: bottomY - height*0.7))
            path.addLine(to: CGPoint(x: centerX, y: topY))
            path.addLine(to: CGPoint(x: centerX + width/6, y: bottomY - height*0.7))
            path.addLine(to: CGPoint(x: centerX + width/4, y: bottomY - height/2))
            path.addLine(to: CGPoint(x: centerX + width/3, y: bottomY - height/3))
            path.addLine(to: CGPoint(x: centerX + width/2, y: bottomY))
            path.closeSubpath()
            
            return path
        }
    }
    
    struct RealisticTreeLayer: View {
        let width: CGFloat
        let height: CGFloat
        let gradient: LinearGradient
        
        var body: some View {
            RealisticTreeLayerShape(width: width, height: height)
                .fill(gradient)
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
        }
    }
    
    struct RealisticTreeLayerShape: Shape {
        let width: CGFloat
        let height: CGFloat
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let centerX = rect.midX
            let bottomY = rect.maxY
            let topY = rect.minY
            
            // Create a realistic, organic tree shape with curves
            path.move(to: CGPoint(x: centerX - width/2, y: bottomY))
            
            // Left side with natural curves
            path.addCurve(
                to: CGPoint(x: centerX - width/3, y: bottomY - height/4),
                control1: CGPoint(x: centerX - width/2.2, y: bottomY - height/8),
                control2: CGPoint(x: centerX - width/2.8, y: bottomY - height/6)
            )
            
            path.addCurve(
                to: CGPoint(x: centerX - width/5, y: bottomY - height/2),
                control1: CGPoint(x: centerX - width/2.5, y: bottomY - height/3),
                control2: CGPoint(x: centerX - width/3.5, y: bottomY - height/2.5)
            )
            
            path.addCurve(
                to: CGPoint(x: centerX - width/8, y: bottomY - height*0.75),
                control1: CGPoint(x: centerX - width/6, y: bottomY - height*0.6),
                control2: CGPoint(x: centerX - width/7, y: bottomY - height*0.7)
            )
            
            // Top point
            path.addLine(to: CGPoint(x: centerX, y: topY))
            
            // Right side with natural curves (mirror of left)
            path.addCurve(
                to: CGPoint(x: centerX + width/8, y: bottomY - height*0.75),
                control1: CGPoint(x: centerX + width/7, y: bottomY - height*0.7),
                control2: CGPoint(x: centerX + width/6, y: bottomY - height*0.6)
            )
            
            path.addCurve(
                to: CGPoint(x: centerX + width/5, y: bottomY - height/2),
                control1: CGPoint(x: centerX + width/3.5, y: bottomY - height/2.5),
                control2: CGPoint(x: centerX + width/2.5, y: bottomY - height/3)
            )
            
            path.addCurve(
                to: CGPoint(x: centerX + width/3, y: bottomY - height/4),
                control1: CGPoint(x: centerX + width/2.8, y: bottomY - height/6),
                control2: CGPoint(x: centerX + width/2.2, y: bottomY - height/8)
            )
            
            path.addLine(to: CGPoint(x: centerX + width/2, y: bottomY))
            path.closeSubpath()
            
            return path
        }
    }
    
    struct Ornament: View {
        let color: Color
        let size: CGFloat
        
        var body: some View {
            ZStack {
                // Main ornament
                Circle()
                    .fill(LinearGradient(
                        colors: [color.opacity(0.8), color, color.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: size, height: size)
                    .shadow(color: color.opacity(0.6), radius: 3, x: 0, y: 2)
                
                // Highlight
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(x: -size * 0.2, y: -size * 0.2)
                
                // Top loop
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.yellow)
                    .frame(width: size * 0.4, height: 4)
                    .offset(y: -size * 0.6)
            }
        }
    }
    
    // MARK: - Animation Functions
    
    private func startChristmasAnimations() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            danceOffset = 20
        }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            bounceScale = 1.2
        }
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            spinRotation = 360
        }
    }
    
    private func startLeprechaunAnimations() {
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            jigOffset = 15
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            bounceScale = 1.1
        }
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            spinRotation = 720
        }
    }
    
    private func startBunnyAnimations() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            bunnyJump = -20
        }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            bounceScale = 1.15
        }
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            spinRotation = 180
        }
    }
    
    private func startHeartAnimations() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            heartPulse = 1.3
        }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            danceOffset = 10
        }
    }
    
    private func startPrideAnimations() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            bounceScale = 1.25
        }
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            spinRotation = 360
        }
    }
    
    private func startGhostAnimations() {
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            danceOffset = 25
        }
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            bounceScale = 1.1
        }
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            spinRotation = 180
        }
    }
    
    private func startFireworksAnimations() {
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            bounceScale = 1.4
        }
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            spinRotation = 360
        }
    }
    
    private func startDefaultAnimations() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            bounceScale = 1.2
        }
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            spinRotation = 360
        }
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Using onReceive instead of @objc for struct compatibility
    }
    
    private func cleanup() {
        // No cleanup needed for onReceive
    }
    
    private func handleCelebrationNotification() {
        print("🎭 [SpecialEffectsView] Received celebration notification")
        triggerFullScreenCelebration()
    }
    
    private func triggerFullScreenCelebration() {
        print("🎭 [SpecialEffectsView] triggerFullScreenCelebration() called")
        
        // Get celebration type from current theme or use default
        let effects = themeManager.currentTheme.specialEffects
        let rawCelebrationType = effects?.celebrationAnimation ?? "default"
        
        // Map celebration types to theme names
        celebrationType = mapCelebrationTypeToTheme(rawCelebrationType)
        
        print("🎭 [SpecialEffectsView] Raw celebration type: '\(rawCelebrationType)'")
        print("🎭 [SpecialEffectsView] Mapped to theme: '\(celebrationType)'")
        print("🎭 [SpecialEffectsView] Will show celebration for: '\(celebrationType)'")
        print("🎭 [SpecialEffectsView] Current theme: '\(ThemeManager.shared.currentTheme.name)'")
        print("🎭 [SpecialEffectsView] Current theme ID: '\(ThemeManager.shared.currentTheme.id)'")
        print("🎭 [SpecialEffectsView] Current theme celebration: '\(ThemeManager.shared.currentTheme.specialEffects?.celebrationAnimation ?? "NONE")'")
        
        // Generate random image index for themes with multiple images
        generateRandomImageIndex(for: celebrationType)
        
        fullScreenCelebration = true
        celebrationActive = true
        
        // Start particles (use default if no particles defined)
        startParticles(type: effects?.particles ?? "default")
        
        // Auto-dismiss after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.dismissFullScreenCelebration()
        }
        
        print("🎭 [SpecialEffectsView] Celebration started: \(celebrationType) (from \(rawCelebrationType))")
    }
    
    // MARK: - Celebration Type Mapping
    
    private func mapCelebrationTypeToTheme(_ celebrationType: String) -> String {
        print("🎭 [SpecialEffectsView] Mapping celebration type: '\(celebrationType)'")
        switch celebrationType {
        case "twinkling_lights", "christmas_lights", "christmas_magic", "santa_wave":
            print("🎭 [SpecialEffectsView] Mapped to christmas")
            return "christmas"
        case "dancing_leprechauns", "irish_riverdance", "st_patricks":
            print("🎭 [SpecialEffectsView] Mapped to st_patricks")
            return "st_patricks"
        case "hopping_bunny", "easter_bunny", "easter", "bunny_hop":
            print("🎭 [SpecialEffectsView] Mapped to easter")
            return "easter"
        case "cupid_arrows", "dancing_hearts", "valentines", "rose_bloom", "heart_beat":
            print("🎭 [SpecialEffectsView] Mapped to valentines")
            return "valentines"
        case "rainbow_explosion", "pride_celebration", "pride":
            print("🎭 [SpecialEffectsView] Mapped to pride")
            return "pride"
        case "dancing_ghosts", "halloween_spooky", "pumpkin_glow":
            print("🎭 [SpecialEffectsView] Mapped to halloween")
            return "halloween"
        case "new_year", "champagne_pop", "champagne_bubbles", "countdown":
            print("🎭 [SpecialEffectsView] Mapped to new_year")
            return "new_year"
                case "spring", "falling_petals", "butterfly_flutter":
                    print("🎭 [SpecialEffectsView] Mapped to spring")
                    return "spring"
                case "winter", "falling_snow", "ice_crystals":
                    print("🎭 [SpecialEffectsView] Mapped to winter")
                    return "winter"
                case "fourth_july", "independence", "fireworks", "star_sparkles", "flag_wave":
                    print("🎭 [SpecialEffectsView] Mapped to fourth_july")
                    return "fourth_july"
        case "thanksgiving", "turkey_dance", "falling_leaves", "turkey_waddle":
            print("🎭 [SpecialEffectsView] Mapped to thanksgiving")
            return "thanksgiving"
        case "hanukkah", "menorah_light", "candle_flicker", "dreidel_spin":
            print("🎭 [SpecialEffectsView] Mapped to hanukkah")
            return "hanukkah"
        case "yule", "winter_solstice", "log_burning", "solstice_light":
            print("🎭 [SpecialEffectsView] Mapped to yule")
            return "yule"
        case "fall", "autumn", "falling_leaves", "pumpkin_glow":
            print("🎭 [SpecialEffectsView] Mapped to fall")
            return "fall"
        case "summer", "ocean_waves", "beach_ball_bounce", "seagull_flight":
            print("🎭 [SpecialEffectsView] Mapped to summer")
            return "summer"
        case "stpatricks", "st_patricks", "rainbow_arc", "leprechaun_dance":
            print("🎭 [SpecialEffectsView] Mapped to stpatricks")
            return "stpatricks"
        default:
            print("🎭 [SpecialEffectsView] Mapped to default (no match found)")
            return "default"
        }
    }
    
    private func dismissFullScreenCelebration() {
        print("🎭 [SpecialEffectsView] Dismissing celebration")
        withAnimation(.easeInOut(duration: 0.5)) {
            fullScreenCelebration = false
        }
        celebrationActive = false
        particles.removeAll()
    }
    
    // MARK: - Particle Management
    
    private func startParticles(type: String = "default") {
        print("🎭 [SpecialEffectsView] Particles completely disabled - too distracting")
        
        // Particles completely disabled for better user experience
        particles.removeAll()
        return // Early return to prevent any particle creation
    }
    

}

// MARK: - Custom Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.35))
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.35),
            control1: CGPoint(x: width * 0.5, y: 0),
            control2: CGPoint(x: 0, y: height * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: 0, y: height * 0.6),
            control2: CGPoint(x: width * 0.5, y: height * 0.8)
        )
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.35),
            control1: CGPoint(x: width * 0.5, y: height * 0.8),
            control2: CGPoint(x: width, y: height * 0.6)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.35),
            control1: CGPoint(x: width, y: height * 0.1),
            control2: CGPoint(x: width * 0.5, y: 0)
        )
        
        return path
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        let points = 5
        let innerRadius = radius * 0.4
        
        for i in 0..<points * 2 {
            let angle = Double(i) * .pi / Double(points)
            let currentRadius = i % 2 == 0 ? radius : innerRadius
            let x = center.x + CGFloat(cos(angle)) * currentRadius
            let y = center.y + CGFloat(sin(angle)) * currentRadius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

struct StylizedChristmasTreeView: View {
    var body: some View {
        Image("christmas_tree_with_sunglasses")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 300, maxHeight: 300)
    }
}

struct PrideCelebrationView: View {
    var body: some View {
        Image("pride_celebration")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 300, maxHeight: 300)
    }
}

#Preview {
    SpecialEffectsView(celebrationActive: .constant(false))
}
