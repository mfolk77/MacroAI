// CameraView.swift
// Complete SwiftUI camera capture system with live preview and photo capture

import SwiftUI
import AVFoundation
import CoreHaptics

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var capturedImage: UIImage?
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject var macroEntryStore: MacroEntryStore
    @State private var showPermissionAlert = false
    @State private var isFlashOn = false
    @State private var isAnalyzing = false
    @State private var detectionOverlay = false
    @State private var confidenceLevel: Double = 0.0
    @State private var isBarcodeMode = false
    @State private var showBarcodeScanner = false
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    @State private var hapticEngine: CHHapticEngine?
    @State private var isFramingGuideVisible = false
    @State private var framingGuideOpacity: Double = 0.0
    @State private var captureButtonScale: CGFloat = 1.0
    @State private var captureButtonRotation: Double = 0.0
    @State private var analysisProgress: Double = 0.0
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        GeometryReader { geometry in
        ZStack {
                // Camera Preview Background
                Color.black
                    .ignoresSafeArea()
                
                if cameraManager.isAuthorized {
                    // Live Camera Preview
                    CameraPreviewView(session: cameraManager.captureSession)
                        .aspectRatio(4/3, contentMode: .fill)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()
                        .overlay(
                            // Premium Framing Guide
                            ZStack {
                                // Corner guides
                                VStack {
                                    HStack {
                                        // Top-left corner
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.white)
                                            .frame(width: 20, height: 3)
                                        Spacer()
                                        // Top-right corner
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.white)
                                            .frame(width: 20, height: 3)
                                    }
                                    Spacer()
                                    HStack {
                                        // Bottom-left corner
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.white)
                                            .frame(width: 20, height: 3)
                                        Spacer()
                                        // Bottom-right corner
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.white)
                                            .frame(width: 20, height: 3)
                                    }
                                }
                                .padding(.horizontal, 60)
                                .padding(.vertical, 120)
                                .opacity(framingGuideOpacity)
                                
                                // Center focus indicator
                                if isAnalyzing {
                                    Circle()
                                        .stroke(themeManager.accentColor, lineWidth: 3)
                                        .frame(width: 200, height: 200)
                                        .scaleEffect(1.2)
                                        .opacity(0.8)
                                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnalyzing)
                                }
                            }
                        )
                        .onAppear {
                            cameraManager.startSession()
                        }
                        .onDisappear {
                            cameraManager.stopSession()
                        }
                    
                    // Camera Controls Overlay
                    VStack {
                        // Top Controls
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            // Barcode Mode Toggle
                            Button(action: { 
                                isBarcodeMode.toggle()
                                if isBarcodeMode {
                                    showBarcodeScanner = true
                                }
                            }) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.title2)
                                    .foregroundColor(isBarcodeMode ? themeManager.accentColor : .white)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: { 
                                isFlashOn.toggle()
                                cameraManager.toggleFlash(isFlashOn)
                            }) {
                                Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                    .font(.title2)
                                    .foregroundColor(isFlashOn ? .yellow : .white)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.top, geometry.safeAreaInsets.top)
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Bottom Controls
                        VStack(spacing: 20) {
                            // Food Recognition Hint with Enhanced Typography
                            VStack(spacing: 8) {
                                if isAnalyzing {
                                    VStack(spacing: 12) {
                                        // Premium progress indicator
                                        ZStack {
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                                                .frame(width: 40, height: 40)
                                            
                                            Circle()
                                                .trim(from: 0, to: analysisProgress)
                                                .stroke(themeManager.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                                .frame(width: 40, height: 40)
                                                .rotationEffect(.degrees(-90))
                                                .animation(.easeInOut(duration: 2.0), value: analysisProgress)
                                        }
                                        
                                        Text("Analyzing your food...")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text("AI is identifying ingredients and calculating nutrition")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(themeManager.primaryColor.opacity(0.9))
                                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                    )
                                } else {
                                    Text("Center your food in the frame")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(12)
                                }
                                
                                // Detection confidence indicator
                                if confidenceLevel > 0 {
                                    Text("Confidence: \(Int(confidenceLevel * 100))%")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(confidenceLevel > 0.7 ? .green : .yellow)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.5))
                                        .cornerRadius(8)
                                }
                            }
                            
                            // Capture Controls
                            HStack(spacing: 60) {
                                // Gallery Button
                                Button(action: {
                                    // TODO: Open photo library
                                }) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: "photo.on.rectangle")
                                                .foregroundColor(.white)
                                        )
                                }
                                
                                // Premium Capture Button
                                Button(action: {
                                    // Premium haptic feedback
                                    playHapticFeedback(.medium)
                                    
                                    // Animate capture button
                                    animateCaptureButton()
                                    
                                    // Show analyzing state with premium animation
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isAnalyzing = true
                                    }
                                    
                                    // Start progress animation
                                    animateAnalysisProgress()
                                    
                                    // Add a small delay to ensure stable image
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        // Capture photo
                                        cameraManager.capturePhoto { image in
                                            DispatchQueue.main.async {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    isAnalyzing = false
                                                }
                                                
                                                if let image = image {
                                                    capturedImage = image
                                                    
                                                    // Analyze the captured image for food recognition
                                                    Task {
                                                        do {
                                                            let macroAIManager = try ServiceFactory.createMacroAIManager()
                                                            print("🔍 [CameraView] Analyzing captured photo for food recognition...")
                                                            
                                                            await macroAIManager.analyzeFoodImage(image)
                                                            
                                                            if let nutritionMacros = macroAIManager.nutritionMacros {
                                                                print("✅ [CameraView] Food analyzed with macros")
                                                                
                                                                // Convert image to data for storage
                                                                let imageData = image.jpegData(compressionQuality: 0.8)
                                                                print("📸 [CameraView] Image data size: \(imageData?.count ?? 0) bytes")
                                                                
                                                                if imageData == nil {
                                                                    print("❌ [CameraView] Failed to convert image to JPEG data")
                                                                } else {
                                                                    print("✅ [CameraView] Successfully converted image to JPEG data")
                                                                }
                                                                
                                                                // Create macro entry from the analyzed food
                                                                let macroEntry = MacroEntry(
                                                                    name: "Photo Analysis",
                                                                    calories: Int(nutritionMacros.calories),
                                                                    protein: Int(nutritionMacros.protein),
                                                                    carbs: Int(nutritionMacros.carbs),
                                                                    fats: Int(nutritionMacros.fat),
                                                                    imageData: imageData,
                                                                    source: .photo
                                                                )
                                                                
                                                                print("📸 [CameraView] Created macro entry with image data: \(macroEntry.imageData?.count ?? 0) bytes")
                                                                print("📸 [CameraView] Macro entry details: \(macroEntry.foodName) - \(macroEntry.calories) cal, \(macroEntry.protein)g protein")
                                                                
                                                                // Save to the store
                                                                let _ = await macroEntryStore.addEntry(macroEntry)
                                                                print("✅ [CameraView] Macro entry added from photo: \(macroEntry.name)")
                                                                
                                                                // Premium success feedback
                                                                DispatchQueue.main.async {
                                                                    // Play success haptic
                                                                    playSuccessHaptic()
                                                                    
                                                                    // Create personalized success message
                                                                    let foodName = "Photo Analysis"
                                                                    let calories = Int(nutritionMacros.calories)
                                                                    let protein = Int(nutritionMacros.protein)
                                                                    let carbs = Int(nutritionMacros.carbs)
                                                                    let fat = Int(nutritionMacros.fat)
                                                                    
                                                                    successMessage = "📸 Photo Added: \(foodName)\n\(calories) cal • \(protein)g protein • \(carbs)g carbs • \(fat)g fat"
                                                                    
                                                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                                        showSuccessMessage = true
                                                                    }
                                                                    
                                                                    // Hide the message after 4 seconds
                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                                                        withAnimation(.easeInOut(duration: 0.5)) {
                                                                            showSuccessMessage = false
                                                                        }
                                                                    }
                                                                }
                                                                
                                                                // Show success feedback
                                                                // You could add a toast notification here
                                                                
                                                            } else {
                                                                print("❌ [CameraView] No food recognized in photo")
                                                                // Premium error handling
                                                                DispatchQueue.main.async {
                                                                    errorMessage = "We couldn't identify the food in your photo. Try taking a clearer picture or use manual entry."
                                                                    showErrorAlert = true
                                                                    playHapticFeedback(.heavy)
                                                                }
                                                            }
                                                        } catch {
                                                            print("❌ [CameraView] Failed to analyze photo: \(error)")
                                                            // Premium error handling
                                                            DispatchQueue.main.async {
                                                                errorMessage = "Analysis failed. Please check your connection and try again."
                                                                showErrorAlert = true
                                                                playHapticFeedback(.heavy)
                                                            }
                                                        }
                                                    }
                                                    
                                                    dismiss()
                                                }
                                            }
                                        }
                                    }
                                }) {
                                    ZStack {
                                        // Outer glow
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 90, height: 90)
                                            .blur(radius: 10)
                                        
                                        // Main button
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 80, height: 80)
                                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                        
                                        // Inner ring
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                            .frame(width: 70, height: 70)
                                        
                                        // Center dot
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: 12, height: 12)
                                    }
                                    .scaleEffect(captureButtonScale)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: captureButtonScale)
                                }
                                // Enable photo capture button - user can choose when to take photos
                                
                                // Settings Button
                                Button(action: {
                                    // TODO: Open camera settings
                                }) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: "gearshape")
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                        }
                    }
                } else {
                    // Permission Request View
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Camera Access Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("MacroAI needs camera access to analyze your food and help you track your nutrition.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            cameraManager.requestPermission()
                        }) {
                            Text("Grant Permission")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                        
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(25)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            cameraManager.requestPermission()
            setupHaptics()
            startFramingGuide()
        }
        .alert("Camera Error", isPresented: $showPermissionAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Unable to access camera. Please check permissions and try again.")
        }
        .alert("Analysis Error", isPresented: $showErrorAlert) {
            Button("Try Again") { 
                showErrorAlert = false
                isAnalyzing = false
            }
            Button("Manual Entry") { 
                showErrorAlert = false
                isAnalyzing = false
                dismiss()
            }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showBarcodeScanner) {
            BarcodeScannerView { barcode in
                // Handle barcode result
                print("📱 [CameraView] Barcode scanned: \(barcode)")
                
                // Look up nutrition data for the barcode
                Task { @MainActor in
                    // Create MacroAIManager with fallback to mock services
                    let macroAIManager: MacroAIManager
                    do {
                        macroAIManager = try ServiceFactory.createMacroAIManager()
                        print("✅ Using production MacroAI manager with API keys")
                    } catch {
                        print("⚠️ API keys not available, using mock MacroAI manager")
                        macroAIManager = ServiceFactory.createMockMacroAIManager()
                    }
                    
                    await macroAIManager.scanBarcode(barcode)
                    
                    if let nutritionData = macroAIManager.nutritionData {
                        print("✅ [CameraView] Nutrition data found: \(nutritionData.foodName)")
                        print("📊 [CameraView] Nutrition details: \(nutritionData.calories) cal, \(nutritionData.protein)g protein, \(nutritionData.carbs)g carbs, \(nutritionData.fats)g fat")
                        
                        // Add the nutrition data to the macro entry store
                        let macroEntry = MacroEntry(
                            name: nutritionData.foodName,
                            calories: Int(nutritionData.calories),
                            protein: Int(nutritionData.protein),
                            carbs: Int(nutritionData.carbs),
                            fats: Int(nutritionData.fats),
                            source: .spoonacular
                        )
                        
                        // Save to the store
                        let _ = await macroEntryStore.addEntry(macroEntry)
                        print("✅ [CameraView] Macro entry added successfully: \(macroEntry.foodName)")
                        
                        // Show success feedback to user
                        DispatchQueue.main.async {
                            // Show a brief success message
                            withAnimation(.easeInOut(duration: 0.3)) {
                                successMessage = "✅ Added: \(nutritionData.foodName) (\(nutritionData.calories) cal)"
                                showSuccessMessage = true
                                
                                // Hide the message after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showSuccessMessage = false
                                    }
                                }
                            }
                        }
                    } else {
                        print("❌ [CameraView] No nutrition data found for barcode: \(barcode)")
                        
                        // Create a basic entry with the barcode as the name
                        let basicEntry = MacroEntry(
                            name: "Barcode: \(barcode)",
                            calories: 0,
                            protein: 0,
                            carbs: 0,
                            fats: 0,
                            source: .spoonacular
                        )
                        
                        // Save to the store
                        let _ = await macroEntryStore.addEntry(basicEntry)
                        print("✅ [CameraView] Created basic entry for barcode: \(barcode)")
                        
                        // Show success feedback to user
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                successMessage = "📱 Barcode scanned: \(barcode)\n(No nutrition data available)"
                                showSuccessMessage = true
                                
                                // Hide the message after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showSuccessMessage = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Premium Success Message Overlay
        if showSuccessMessage {
            VStack {
                Spacer()
                
                VStack(spacing: 8) {
                    // Success icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                        .scaleEffect(showSuccessMessage ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccessMessage)
                    
                    // Success message
                    Text(successMessage)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green.opacity(0.9), Color.green.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                removal: .move(edge: .bottom).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Premium Haptic Feedback
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("❌ Haptic engine failed to start: \(error)")
        }
    }
    
    private func playHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    private func playSuccessHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    // MARK: - Premium Visual Guidance
    
    private func startFramingGuide() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            framingGuideOpacity = 0.3
        }
    }
    
    private func animateCaptureButton() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            captureButtonScale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                captureButtonScale = 1.0
            }
        }
    }
    
    private func animateAnalysisProgress() {
        withAnimation(.easeInOut(duration: 2.0)) {
            analysisProgress = 1.0
        }
    }
}

// MARK: - Camera Preview View
// Note: CameraPreviewView is defined in BarcodeScannerView.swift to avoid duplication
