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
    @State private var currentPage = 0
    @State private var showingOnboarding = false
    @Binding var isOnboardingComplete: Bool
    
    let features = [
        OnboardingFeature(
            title: "Snap Food",
            description: "Take a photo of your food and let AI identify and calculate nutrition instantly",
            icon: "camera.fill",
            color: .blue
        ),
        OnboardingFeature(
            title: "Manual Entry",
            description: "Add foods manually with our comprehensive nutrition database",
            icon: "pencil",
            color: .green
        ),
        OnboardingFeature(
            title: "Food Search",
            description: "Search thousands of foods and get detailed nutrition information",
            icon: "magnifyingglass",
            color: .orange
        ),
        OnboardingFeature(
            title: "Daily Streak Tracking",
            description: "Track your daily nutrition goals and build healthy habits with streak counting",
            icon: "flame.fill",
            color: .red
        ),
        OnboardingFeature(
            title: "AI Nutrition Assistant",
            description: "Get personalized nutrition advice and macro guidance from your AI assistant",
            icon: "brain.head.profile",
            color: .purple
        ),
        OnboardingFeature(
            title: "Premium Features",
            description: "Unlock advanced features and premium themes with 7-day free trial",
            icon: "crown.fill",
            color: .yellow
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
            
            VStack(spacing: 0) {
                // Page indicator
                HStack {
                    ForEach(0..<features.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 50)
                .padding(.bottom, 30)
                
                // Feature content
                TabView(selection: $currentPage) {
                    ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                        VStack(spacing: 30) {
                            Spacer()
                            
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(feature.color.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: feature.icon)
                                    .font(.system(size: 50))
                                    .foregroundColor(feature.color)
                            }
                            
                            // Screen 1: Snap Food – usage badge
                            if feature.title == "Snap Food" {
                                Text("3 free scans daily")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(10)
                            }
                            
                            // Title and description
                            VStack(spacing: 16) {
                                if feature.title == "AI Nutrition Assistant" {
                                    Text("⭐ PREMIUM · AI Nutrition Assistant")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text(feature.title)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                
                                Text(feature.description)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                if feature.title == "Snap Food" {
                                    Text("Upgrade for unlimited scanning")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                if feature.title == "AI Nutrition Assistant" {
                                    Text("Included with premium subscription")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                if feature.title == "Food Search" {
                                    Text("Advanced search filters available with premium")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                            
                            Spacer()
                            
                            if feature.title == "Premium Features" {
                                VStack(spacing: 10) {
                                    Text("Unlock the full MacroAI experience")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("✨ Unlimited AI food scanning")
                                        Text("🥑 Advanced diet plans (Keto, Mediterranean, High-Protein)")
                                        Text("🎨 Premium themes & customization")
                                        Text("📊 Detailed progress analytics")
                                        Text("📈 Macro trend analysis")
                                        Text("🍽️ AI meal planning suggestions")
                                        Text("📱 Data export capabilities")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                                    
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
                                            // Continue without triggering paywall
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                    }
                    
                    Spacer()
                    
                    if currentPage < features.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
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
                        .padding()
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.1), value: true)
                    }
                }
                .padding(.bottom, 50)
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
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
} 