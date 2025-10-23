//
//  OnboardingView.swift
//  MacroAI
//
//  Custom onboarding view for MacroAI nutrition tracking app

import SwiftUI

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var showingOnboarding = false
    @Binding var isOnboardingComplete: Bool
    
    let features = [
        OnboardingFeature(
            title: "100% Private Food Recognition",
            description: "The ONLY macro app that processes your food photos on your device. Your photos never leave your phone.",
            icon: "lock.shield.fill",
            color: .purple
        ),
        OnboardingFeature(
            title: "Official Nutrition Database",
            description: "Powered by the same nutrition data used by nutritionists and dietitians. Accurate, reliable, and unlimited with subscription.",
            icon: "leaf.fill",
            color: .green
        ),
        OnboardingFeature(
            title: "AI-Powered Coaching",
            description: "Get personalized nutrition advice, meal planning, and macro coaching from our on-device AI assistant.",
            icon: "brain.head.profile",
            color: .blue
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if currentStep < features.count {
                // Thought bubble style onboarding
                VStack {
                    Spacer()
                    
                    // Main content area
                    VStack(spacing: 30) {
                        // Icon with enhanced visibility
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: features[currentStep].icon)
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        // Thought bubble content
                        VStack(spacing: 16) {
                            Text(features[currentStep].title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                            
                            Text(features[currentStep].description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.95))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Navigation with thought bubble style
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
                                print("🔄 [OnboardingView] Get Started button tapped")
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                completeOnboarding()
                                Analytics.onboardingCompleted()
                                if !PaywallState.shared.hasShownOnboardingPaywallThisSession {
                                    Analytics.onboardingPaywallShown()
                                    NotificationCenter.default.post(name: NSNotification.Name("ShowPaywallOnboarding"), object: nil)
                                    PaywallState.shared.hasShownOnboardingPaywallThisSession = true
                                }
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
            } else {
                // Final step - Premium benefits
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Text("Unlock the full MacroAI experience")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("Coach Mode nudges & streaks")
                            }
                            HStack(spacing: 12) {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.blue)
                                Text("Unlimited AI chat (on‑device)")
                            }
                            HStack(spacing: 12) {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.green)
                                Text("Diet packs (Keto, Mediterranean, High‑Protein)")
                            }
                            HStack(spacing: 12) {
                                Image(systemName: "paintbrush.fill")
                                    .foregroundColor(.purple)
                                Text("Seasonal themes & customization")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.95))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        Text("7-Day Free Trial • Cancel Anytime")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                        
                        HStack(spacing: 12) {
                            Button("Start Free Trial") {
                                Analytics.onboardingPaywallShown()
                                NotificationCenter.default.post(name: NSNotification.Name("ShowPaywallOnboarding"), object: nil)
                                PaywallState.shared.hasShownOnboardingPaywallThisSession = true
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Continue with Free Version") {
                                completeOnboarding()
                                Analytics.onboardingCompleted()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            showingOnboarding = true
            Analytics.featureUse("onboarding", action: "start")
        }
    }
    
    private func completeOnboarding() {
        print("🔄 [OnboardingView] completeOnboarding() called")
        UserDefaults.standard.set(true, forKey: "OnboardingSeen")
        print("✅ [OnboardingView] UserDefaults updated")
        isOnboardingComplete = true
        print("✅ [OnboardingView] isOnboardingComplete set to true")
        print("✅ [OnboardingView] Onboarding completed - user can now access main app")
        Analytics.featureUse("onboarding", action: "complete")
        
        // Trigger interactive demo after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: NSNotification.Name("ShowInteractiveDemo"), object: nil)
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
} 