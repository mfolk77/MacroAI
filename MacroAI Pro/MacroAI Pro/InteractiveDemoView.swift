import SwiftUI

struct InteractiveDemoView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var showingCamera = false
    @State private var showingCoach = false
    @State private var showingFoodSearch = false
    @State private var showingSettings = false
    @State private var showingDietSelection = false
    @State private var demoCompleted = false
    
    // Callbacks to open real app features
    let onOpenCamera: () -> Void
    let onOpenCoach: () -> Void
    let onOpenFoodSearch: () -> Void
    let onOpenSettings: () -> Void
    
    let demoSteps = [
        DemoStep(
            title: "Welcome to MacroAI!",
            description: "Let's take a hands-on tour of your new macro tracking app. Everything you do here is just a demo - it won't affect your real data!",
            icon: "sparkles",
            color: .blue,
            action: .none
        ),
        DemoStep(
            title: "Camera & Auto-Macro Tracking",
            description: "Let's try the camera! Tap the camera button to scan a barcode or take a photo of food. The nutrition info automatically gets added to your daily macros - no manual entry needed!",
            icon: "camera.fill",
            color: .green,
            action: .camera
        ),
        DemoStep(
            title: "AI Coach Assistant",
            description: "Meet your personal nutrition coach! Tap the chat icon to get personalized advice. You get one free question, then unlimited with subscription.",
            icon: "brain.head.profile",
            color: .purple,
            action: .coach
        ),
        DemoStep(
            title: "Food Search & Manual Entry",
            description: "Can't find what you're looking for? Use the food search to browse thousands of items in our database.",
            icon: "magnifyingglass",
            color: .orange,
            action: .foodSearch
        ),
        DemoStep(
            title: "Settings & Diet Selection",
            description: "Let's set up your diet preferences! Tap settings to choose your diet type and customize your macro targets.",
            icon: "gearshape.fill",
            color: .gray,
            action: .settings
        ),
        DemoStep(
            title: "You're All Set!",
            description: "You've seen the key features! Start tracking your macros and reach your health goals with MacroAI.",
            icon: "checkmark.circle.fill",
            color: .green,
            action: .complete
        )
    ]
    
    var body: some View {
        ZStack {
            // Simple background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Simple demo content
                if currentStep < demoSteps.count {
                    let step = demoSteps[currentStep]
                    
                    VStack(spacing: 16) {
                        // Simple icon
                        Image(systemName: step.icon)
                            .font(.system(size: 50))
                            .foregroundColor(step.color)
                        
                        Text(step.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Simple navigation
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Back") {
                            currentStep -= 1
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(16)
                    }
                    
                    Spacer()
                    
                    if currentStep < demoSteps.count - 1 {
                        Button("Try It!") {
                            handleStepAction()
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(16)
                    } else {
                        Button("Get Started!") {
                            completeDemo()
                        }
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            Analytics.featureUse("interactive_demo", action: "started")
            // Restore current step if demo was interrupted
            if let savedStep = UserDefaults.standard.object(forKey: "DemoCurrentStep") as? Int {
                currentStep = savedStep
                // Advance to next step since we're resuming
                if currentStep < demoSteps.count - 1 {
                    currentStep += 1
                    UserDefaults.standard.set(currentStep, forKey: "DemoCurrentStep")
                }
            }
        }
    }
    
    private func handleStepAction() {
        let step = demoSteps[currentStep]
        
        switch step.action {
        case .camera:
            // Save current step and close demo
            UserDefaults.standard.set(currentStep, forKey: "DemoCurrentStep")
            UserDefaults.standard.set(true, forKey: "DemoMode")
            isPresented = false
            onOpenCamera()
        case .coach:
            // Save current step and close demo
            UserDefaults.standard.set(currentStep, forKey: "DemoCurrentStep")
            isPresented = false
            onOpenCoach()
        case .foodSearch:
            // Save current step and close demo
            UserDefaults.standard.set(currentStep, forKey: "DemoCurrentStep")
            isPresented = false
            onOpenFoodSearch()
        case .settings:
            // Save current step and close demo
            UserDefaults.standard.set(currentStep, forKey: "DemoCurrentStep")
            isPresented = false
            onOpenSettings()
        case .none, .complete:
            nextStep()
        }
    }
    
    
    private func addDemoMacroEntry() {
        // Create a demo macro entry to show in the app
        let demoEntry = [
            "foodName": "Demo Apple",
            "calories": 95,
            "protein": 0.5,
            "carbs": 25.0,
            "fat": 0.3,
            "servingSize": "1 medium",
            "timestamp": Date()
        ] as [String: Any]
        
        // Store demo results
        UserDefaults.standard.set(demoEntry, forKey: "DemoMacroEntry")
        UserDefaults.standard.set(true, forKey: "ShowDemoResults")
        
        // Post notification to show demo results
        NotificationCenter.default.post(name: Notification.Name("ShowDemoResults"), object: demoEntry)
    }
    
    private func nextStep() {
        currentStep += 1
        
        if currentStep >= demoSteps.count {
            completeDemo()
        } else {
            // Save progress
            UserDefaults.standard.set(currentStep, forKey: "DemoCurrentStep")
        }
    }
    
    private func completeDemo() {
        UserDefaults.standard.set(true, forKey: "InteractiveDemoCompleted")
        UserDefaults.standard.removeObject(forKey: "DemoCurrentStep")
        UserDefaults.standard.set(false, forKey: "DemoMode")
        Analytics.featureUse("interactive_demo", action: "completed")
        isPresented = false
    }
}

struct DemoStep {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: DemoAction
    
    enum DemoAction {
        case none
        case camera
        case coach
        case foodSearch
        case settings
        case complete
    }
}


#Preview {
    InteractiveDemoView(
        isPresented: .constant(true),
        onOpenCamera: {},
        onOpenCoach: {},
        onOpenFoodSearch: {},
        onOpenSettings: {}
    )
}
