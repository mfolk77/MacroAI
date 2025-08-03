//
//  AnnoyingPaywallView.swift
//  MacroAI
//
//  Simplified paywall without distracting animations

import SwiftUI
import StoreKit
internal import Combine

struct AnnoyingPaywallView: View {
    @State private var timeRemaining = 30
    @State private var canDismiss = false
    @State private var isPurchasing = false
    @State private var showTrialActivated = false
    @Binding var isPresented: Bool
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Simple background
            Color.black
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 30) {
                // Simple header
                VStack(spacing: 20) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.yellow)
                    
                    VStack(spacing: 12) {
                        Text("Premium")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Unlock all features and diet plans")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Features list
                VStack(spacing: 24) {
                    PremiumFeatureRow(
                        icon: "crown.fill",
                        title: "Premium Diet Plans",
                        description: "Access to medical and specialized diets",
                        color: .yellow
                    )
                    
                    PremiumFeatureRow(
                        icon: "heart.fill",
                        title: "Advanced Analytics",
                        description: "Detailed nutrition insights and trends",
                        color: .red
                    )
                    
                    PremiumFeatureRow(
                        icon: "camera.fill",
                        title: "Unlimited Scanning",
                        description: "No limits on food scanning and analysis",
                        color: .blue
                    )
                    
                    PremiumFeatureRow(
                        icon: "chart.bar.fill",
                        title: "Custom Reports",
                        description: "Personalized nutrition reports and goals",
                        color: .green
                    )
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Timer display (simplified)
                VStack(spacing: 10) {
                    Text("\(timeRemaining)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(canDismiss ? .green : .white)
                    
                    Text("seconds remaining")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 20)
                
                // Action buttons
                VStack(spacing: 16) {
                    // Premium upgrade button
                    Button(action: activateTrial) {
                        HStack(spacing: 12) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 18, weight: .semibold))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start 7-Day Free Trial")
                                    .font(.system(size: 18, weight: .bold))
                                
                                Text("Then $9.99/month")
                                    .font(.caption)
                                    .opacity(0.9)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .background(Color.blue)
                        .cornerRadius(16)
                    }
                    .disabled(isPurchasing)
                    
                    // Dismiss button
                    Button(action: dismissPaywall) {
                        HStack {
                            Image(systemName: canDismiss ? "xmark.circle.fill" : "clock.fill")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(canDismiss ? "Maybe Later" : "Wait \(timeRemaining) seconds")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(canDismiss ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canDismiss ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                        )
                    }
                    .disabled(!canDismiss)
                }
                .padding(.horizontal, 30)
                
                // Terms section
                VStack(spacing: 8) {
                    Text("Cancel anytime. No commitment required.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Text("Terms of Service • Privacy Policy")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .padding(.vertical, 20)
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canDismiss = true
            }
        }
        .alert("Trial Activated!", isPresented: $showTrialActivated) {
            Button("Great!") {
                dismissPaywall()
            }
        } message: {
            Text("Your 7-day free trial has been activated. Enjoy premium features!")
        }
    }
    
    private func activateTrial() {
        isPurchasing = true
        
        // Simulate purchase process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Set trial activation date
            UserDefaults.standard.set(Date(), forKey: "TrialStartDate")
            UserDefaults.standard.set(true, forKey: "IsPremiumTrial")
            
            isPurchasing = false
            showTrialActivated = true
        }
    }
    
    private func dismissPaywall() {
        isPresented = false
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced icon with glow effect
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Premium checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    AnnoyingPaywallView(isPresented: .constant(true))
} 