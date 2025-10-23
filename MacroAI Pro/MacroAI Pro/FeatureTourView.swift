import SwiftUI

struct FeatureTourView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var showingHighlight = false
    
    let features = [
        FeatureTourStep(
            title: "Welcome to MacroAI!",
            description: "Let's take a quick tour of your new macro tracking app.",
            icon: "sparkles",
            color: .blue,
            highlightType: .none
        ),
        FeatureTourStep(
            title: "Camera & Barcode Scanning",
            description: "Tap the camera button to take photos of your food or scan barcodes for instant nutrition data.",
            icon: "camera.fill",
            color: .green,
            highlightType: .camera
        ),
        FeatureTourStep(
            title: "AI Chat Assistant",
            description: "Tap the chat icon to get personalized nutrition advice and meal planning help.",
            icon: "brain.head.profile",
            color: .purple,
            highlightType: .chat
        ),
        FeatureTourStep(
            title: "Manual Entry",
            description: "Use the + button to manually log foods when you know the exact nutrition info.",
            icon: "plus.circle.fill",
            color: .orange,
            highlightType: .manualEntry
        ),
        FeatureTourStep(
            title: "Settings & Premium",
            description: "Tap the gear icon to customize your experience and upgrade to unlock unlimited features.",
            icon: "gearshape.fill",
            color: .gray,
            highlightType: .settings
        )
    ]
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow tapping background to dismiss
                    if currentStep == features.count - 1 {
                        completeTour()
                    }
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Feature content
                if currentStep < features.count {
                    let feature = features[currentStep]
                    
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(feature.color.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: feature.icon)
                                .font(.system(size: 40))
                                .foregroundColor(feature.color)
                        }
                        
                        // Content
                        VStack(spacing: 16) {
                            Text(feature.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(feature.description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
                // Navigation
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    if currentStep < features.count - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep += 1
                            }
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    } else {
                        Button("Get Started") {
                            completeTour()
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Start the tour
            Analytics.featureUse("feature_tour", action: "started")
        }
    }
    
    private func completeTour() {
        UserDefaults.standard.set(true, forKey: "FeatureTourCompleted")
        Analytics.featureUse("feature_tour", action: "completed")
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

struct FeatureTourStep {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let highlightType: HighlightType
    
    enum HighlightType {
        case none
        case camera
        case chat
        case manualEntry
        case settings
    }
}

#Preview {
    FeatureTourView(isPresented: .constant(true))
}
