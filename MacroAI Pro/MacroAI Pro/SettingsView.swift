import SwiftData
import SwiftUI
import AuthenticationServices
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("selectedTheme") private var selectedTheme: String = "System"
    @AppStorage("textSize") private var textSize: String = "Medium"
    @AppStorage("highContrast") private var highContrast: Bool = false
    @AppStorage("reduceMotion") private var reduceMotion: Bool = false
    @StateObject private var dietManager = DietManager.shared
    @State private var showingTextSizePicker = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingPremiumUpgrade = false
    @State private var showingMarketplace = false
    @State private var showingDietSelection = false
    @State private var showingAppleHealth = false
    @State private var showingSignInWithApple = false
    @State private var showingOpenAIKeyInput = false
    @State private var showingSpoonacularKeyInput = false
    @State private var showingPhotoGallery = false
    @ObservedObject var macroEntryStore: MacroEntryStore
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @EnvironmentObject private var storeKitManager: StoreKitManager
    
    // MARK: - Color Scheme Management
    
    private func applyColorScheme(_ scheme: String) {
        switch scheme {
        case "Light":
            setColorScheme(.light)
        case "Dark":
            setColorScheme(.dark)
        case "System":
            setColorScheme(nil)
        default:
            break
        }
    }
    
    private func setColorScheme(_ colorScheme: ColorScheme?) {
        // Update the stored theme preference
        switch colorScheme {
        case .light:
            selectedTheme = "Light"
        case .dark:
            selectedTheme = "Dark"
        case nil:
            selectedTheme = "System"
        default:
            selectedTheme = "System"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Upgrade to Premium Section
                    VStack(spacing: 0) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "star.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upgrade to Premium")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Unlock all features & diet plans")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Upgrade") {
                                showingPremiumUpgrade = true
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // MARKETPLACE Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MARKETPLACE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button(action: { showingMarketplace = true }) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue)
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 14))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Diet Packs & Themes")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Discover new diet plans and seasonal themes")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // DIET PLAN Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DIET PLAN")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button(action: { showingDietSelection = true }) {
                            HStack {
                                Image(systemName: dietManager.currentDiet.icon)
                                    .foregroundColor(dietManager.currentDiet.primaryColor)
                                    .font(.system(size: 25))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dietManager.currentDiet.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(dietManager.currentDiet.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    if dietManager.currentDiet.isPremium {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                    }
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // APPLE HEALTH INTEGRATION Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("APPLE HEALTH INTEGRATION")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Apple Health")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Please authorize HealthKit access in Settings")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                            
                            Button("Connect to Apple Health") {
                                showingAppleHealth = true
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(25)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // ACCOUNT Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACCOUNT")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            SignInWithAppleButton(
                                onRequest: { request in
                                    request.requestedScopes = [ASAuthorization.Scope.fullName, ASAuthorization.Scope.email]
                                },
                                onCompletion: { result in
                                    switch result {
                                    case .success(let authResults):
                                        print("✅ Sign in with Apple successful")
                                        if let appleIDCredential = authResults as? ASAuthorizationAppleIDCredential {
                                            // Store user ID for future reference
                                            UserDefaults.standard.set(appleIDCredential.user, forKey: "AppleUserID")
                                            
                                            // Store user info if provided
                                            if let fullName = appleIDCredential.fullName {
                                                var nameComponents = PersonNameComponents()
                                                nameComponents.givenName = fullName.givenName
                                                nameComponents.familyName = fullName.familyName
                                                
                                                if let nameData = try? JSONEncoder().encode(nameComponents) {
                                                    UserDefaults.standard.set(nameData, forKey: "AppleUserName")
                                                }
                                            }
                                            
                                            if let email = appleIDCredential.email {
                                                UserDefaults.standard.set(email, forKey: "AppleUserEmail")
                                            }
                                        }
                                        dismiss()
                                    case .failure(let error):
                                        print("❌ Sign in with Apple failed: \(error)")
                                        dismiss()
                                    }
                                }
                            )
                            .frame(height: 50)
                            .cornerRadius(12)
                            
                            Button("Restore Purchases") {
                                // Restore purchases functionality
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // APPEARANCE Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("APPEARANCE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            Picker("Theme", selection: $selectedTheme) {
                                Text("Light").tag("Light")
                                Text("Dark").tag("Dark")
                                Text("System").tag("System")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .onChange(of: selectedTheme) { _, newValue in
                                applyColorScheme(newValue)
                            }
                        }
                    }
                    
                    // DEVELOPER Section (COMPLETELY HIDDEN)
                    #if false
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DEVELOPER")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            Button(action: {
                                // Simulate Elite tier for testing
                                UserDefaults.standard.set(true, forKey: "isTestFlightUser")
                                // Force refresh subscription status
                                Task {
                                    await subscriptionManager.checkSubscriptionStatus()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                    Text("Activate Elite Tier (Testing)")
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                // Reset to basic tier
                                UserDefaults.standard.removeObject(forKey: "isTestFlightUser")
                                // Force refresh subscription status
                                Task {
                                    await subscriptionManager.checkSubscriptionStatus()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(.red)
                                    Text("Reset to Basic Tier")
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                // Reset onboarding for testing
                                UserDefaults.standard.removeObject(forKey: "OnboardingSeen")
                                print("🔄 [SettingsView] Onboarding reset - will show on next app launch")
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.blue)
                                    Text("Reset Onboarding")
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                // Test image storage
                                Task {
                                    await macroEntryStore.testImageStorage()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "photo.badge.plus")
                                        .foregroundColor(.green)
                                    Text("Test Image Storage")
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                // Test barcode scanner functionality
                                print("🔍 [SettingsView] Testing barcode scanner...")
                                // This will help verify if the barcode scanner is working
                            }) {
                                HStack {
                                    Image(systemName: "barcode.viewfinder")
                                        .foregroundColor(.blue)
                                    Text("Test Barcode Scanner")
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                // Reset streak counter for testing
                                let defaults = UserDefaults.standard
                                defaults.set(0, forKey: "currentStreak")
                                defaults.removeObject(forKey: "lastEntryDate")
                                print("🔄 [SettingsView] Streak counter reset to 0")
                            }) {
                                HStack {
                                    Image(systemName: "flame")
                                        .foregroundColor(.orange)
                                    Text("Reset Streak Counter")
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                    #endif
                    
                    // YOUR DATA Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("YOUR DATA")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                        .foregroundColor(themeManager.primaryColor)
                                        .frame(width: 20)
                                    Text("Macro Entries")
                                        .font(.subheadline)
                                    Spacer()
                                }
                                Text("0 meals tracked")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 28)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            Button(action: {
                                showingPhotoGallery = true
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "photo.on.rectangle")
                                            .foregroundColor(.green)
                                            .frame(width: 20)
                                        Text("Food Photos")
                                            .font(.subheadline)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    Text("\(macroEntryStore.entriesWithPhotos.count) photos • \(String(format: "%.1f", macroEntryStore.estimatedPhotoStorageMB)) MB")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 28)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // API CONFIGURATION Section (COMPLETELY HIDDEN)
                    #if false
                    VStack(alignment: .leading, spacing: 12) {
                        Text("API CONFIGURATION")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.purple)
                                        .frame(width: 20)
                                    Text("OpenAI API Key")
                                        .font(.subheadline)
                                    Spacer()
                                    if OpenAIAPI.hasValidAPIKey() {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    } else {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                }
                                Text(OpenAIAPI.hasValidAPIKey() ? "Configured" : "Not configured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 28)
                                
                                if !OpenAIAPI.hasValidAPIKey() {
                                    Button("Add OpenAI API Key") {
                                        showingOpenAIKeyInput = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(themeManager.primaryColor)
                                    .padding(.leading, 28)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "fork.knife")
                                        .foregroundColor(.orange)
                                        .frame(width: 20)
                                    Text("Spoonacular API Key")
                                        .font(.subheadline)
                                    Spacer()
                                    if SpoonacularRecipeAPI.hasValidAPIKey() {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    } else {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                }
                                Text(SpoonacularRecipeAPI.hasValidAPIKey() ? "Configured" : "Not configured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 28)
                                
                                if !SpoonacularRecipeAPI.hasValidAPIKey() {
                                    Button("Add Spoonacular API Key") {
                                        showingSpoonacularKeyInput = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(themeManager.primaryColor)
                                    .padding(.leading, 28)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    #endif
                    
                    // LEGAL & DATA USE Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("LEGAL & DATA USE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Attribution & Data Use Disclosure")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Nutrition data is provided by the Spoonacular API. All recipes, ingredients, and nutritional facts are sourced from Spoonacular's content partners. We credit all original sources where applicable. This app does not permanently store or scrape Spoonacular content. Nutritional data is cached for no more than one hour per Spoonacular's Terms of Use.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("AI Analysis Disclosure")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Image analysis is performed by OpenAI's GPT-4o Vision model to identify food items. Food names are then matched to Spoonacular's nutrition database.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("User Data Policy")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("User-submitted images are retained for up to 7 days to support re-analysis and user review. These images are owned by the user and are not shared with third parties outside of OpenAI or Spoonacular during analysis.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Medical Disclaimer")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Macro AI Pro is for educational and informational use only. It is not intended to provide medical advice, diagnosis, or treatment. Consult a licensed healthcare provider before making dietary or health decisions. This app does not replace professional medical care.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // SUPPORT Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SUPPORT")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            SupportRow(icon: "envelope.fill", title: "Send Feedback", action: {
                                if let url = URL(string: "mailto:support@folktechai.com") {
                                    UIApplication.shared.open(url)
                                }
                            })
                            SupportRow(icon: "globe", title: "Support Website", action: {
                                if let url = URL(string: "https://folktechai.com") {
                                    UIApplication.shared.open(url)
                                }
                            })
                            SupportRow(icon: "lightbulb.fill", title: "Request Feature", action: {
                                if let url = URL(string: "mailto:support@folktechai.com?subject=Feature Request") {
                                    UIApplication.shared.open(url)
                                }
                            })
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // ABOUT Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ABOUT")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            SupportRow(icon: "info.circle", title: "Version", value: "1.3.3", action: {})
                            SupportRow(icon: "person.circle", title: "Developer", value: "FolkTech AI", action: {})
                            SupportRow(icon: "hand.raised", title: "Privacy Policy", action: { showingPrivacyPolicy = true })
                            SupportRow(icon: "doc.text", title: "Terms of Service", action: { showingTermsOfService = true })
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPremiumUpgrade) {
            PaywallView()
        }
        .sheet(isPresented: $showingMarketplace) {
            MarketplaceView()
        }
        .sheet(isPresented: $showingDietSelection) {
            DietSelectionView()
                .environmentObject(storeKitManager)
        }
        .sheet(isPresented: $showingAppleHealth) {
            AppleHealthView()
        }
        .sheet(isPresented: $showingSignInWithApple) {
            SignInWithAppleView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingOpenAIKeyInput) {
            APIKeyInputView(
                title: "OpenAI API Key",
                placeholder: "sk-...",
                onSave: { key in
                    OpenAIAPI.saveAPIKey(key)
                }
            )
        }
        .sheet(isPresented: $showingSpoonacularKeyInput) {
            APIKeyInputView(
                title: "Spoonacular API Key",
                placeholder: "Enter your Spoonacular API key",
                onSave: { key in
                    SpoonacularRecipeAPI.saveAPIKey(key)
                }
            )
        }
        .sheet(isPresented: $showingPhotoGallery) {
            PhotoGalleryView(macroEntryStore: macroEntryStore)
        }
    }
}

// MARK: - Supporting Views

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Upgrade to Premium")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Unlock all features and diet plans")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    FeatureRow(icon: "crown.fill", title: "All Diet Plans", description: "Access to all specialized diet plans")
                    FeatureRow(icon: "heart.fill", title: "Apple Health Integration", description: "Sync with Apple Health")
                    FeatureRow(icon: "paintbrush.fill", title: "Premium Themes", description: "Exclusive seasonal themes")
                    FeatureRow(icon: "chart.bar.fill", title: "Advanced Analytics", description: "Detailed nutrition insights")
                }
                
                Spacer()
                
                Button("Upgrade Now") {
                    dismiss()
                    // Show the actual paywall after dismissing this view
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // This would need to be handled by the parent view
                        // For now, just dismiss - the main settings button should be used
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AppleHealthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Apple Health Integration")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 12) {
                    Text("Connect MacroAI to Apple Health to sync your nutrition data and activity levels.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("You'll be able to choose which health data to share with MacroAI.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button("Allow MacroAI to Access Health Data") {
                    Task {
                        await healthKitManager.requestAuthorization()
                        
                        // Give iOS time to show the permission dialog
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        
                        DispatchQueue.main.async {
                            if healthKitManager.isAuthorized {
                                print("✅ Apple Health connected successfully")
                                // Show success message or update UI
                            } else {
                                print("ℹ️ Apple Health permissions can be changed in iOS Settings > Privacy & Security > Health")
                            }
                            dismiss()
                        }
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SignInWithAppleView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Sign in with Apple")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Securely sign in to sync your data across devices and restore purchases.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [ASAuthorization.Scope.fullName, ASAuthorization.Scope.email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            print("✅ Sign in with Apple successful")
                            if let appleIDCredential = authResults as? ASAuthorizationAppleIDCredential {
                                // Store user ID for future reference
                                UserDefaults.standard.set(appleIDCredential.user, forKey: "AppleUserID")
                                
                                // Store user info if provided
                                if let fullName = appleIDCredential.fullName {
                                    var nameComponents = PersonNameComponents()
                                    nameComponents.givenName = fullName.givenName
                                    nameComponents.familyName = fullName.familyName
                                    
                                    if let nameData = try? JSONEncoder().encode(nameComponents) {
                                        UserDefaults.standard.set(nameData, forKey: "AppleUserName")
                                    }
                                }
                                
                                if let email = appleIDCredential.email {
                                    UserDefaults.standard.set(email, forKey: "AppleUserEmail")
                                }
                            }
                            dismiss()
                        case .failure(let error):
                            print("❌ Sign in with Apple failed: \(error)")
                            dismiss()
                        }
                    }
                )
                .frame(height: 50)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}





struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last updated: January 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Your privacy is important to us. This policy describes how MacroAI collects, uses, and protects your information.")
                        .font(.body)
                    
                    Text("Data Collection")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("We collect nutrition data you enter, photos you take for food analysis, and basic app usage statistics to improve your experience.")
                        .font(.body)
                    
                    Text("Data Usage")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Your data is used to provide personalized nutrition insights, improve our food recognition technology, and enhance app functionality.")
                        .font(.body)
                    
                    Text("Data Protection")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("We implement industry-standard security measures to protect your personal information and never share it with third parties without your consent.")
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last updated: January 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("By using MacroAI, you agree to these terms of service.")
                        .font(.body)
                    
                    Text("App Usage")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("MacroAI is designed for nutrition tracking and meal planning. It is not intended to provide medical advice.")
                        .font(.body)
                    
                    Text("User Responsibilities")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("You are responsible for the accuracy of information you enter and for consulting healthcare professionals for medical advice.")
                        .font(.body)
                    
                    Text("Limitation of Liability")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("FolkTech AI is not liable for any decisions made based on the app's recommendations or data analysis.")
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SupportRow: View {
    let icon: String
    let title: String
    let value: String?
    let action: () -> Void
    
    init(icon: String, title: String, value: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.value = value
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                Spacer()
                if let value = value {
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    if let container = try? ModelContainer(for: MacroEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) {
        let context = container.mainContext
        let store = MacroEntryStore(modelContext: context)
        return SettingsView(macroEntryStore: store)
            .task {
                await store.addSampleData()
            }
    } else {
        return Text("Failed to create preview")
    }
}

// MARK: - API Key Input View

struct APIKeyInputView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let placeholder: String
    let onSave: (String) -> Void
    
    @State private var apiKey = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(title)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Paste from Clipboard") {
                            apiKey = UIPasteboard.general.string ?? ""
                        }
                        .buttonStyle(.bordered)
                        .padding(.bottom, 4)
                        
                        SecureField(placeholder, text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        
                        Button("Save API Key") {
                            onSave(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
                            apiKey = ""
                            showConfirmation = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Button("Clear API Key") {
                            onSave("")
                            apiKey = ""
                            showConfirmation = false
                        }
                        .foregroundStyle(.red)
                        .buttonStyle(.bordered)
                        .padding(.bottom, 4)
                        
                        if showConfirmation {
                            Text("API Key saved to Keychain!")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Section(header: Text("Get API Key")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You can get your API key from:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if title.contains("OpenAI") {
                            Link("OpenAI Platform", destination: URL(string: "https://platform.openai.com/api-keys")!)
                                .font(.caption)
                        } else {
                            Link("Spoonacular Food API", destination: URL(string: "https://spoonacular.com/food-api")!)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 

