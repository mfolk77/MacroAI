// BarcodeScannerView.swift
// Dedicated barcode scanning interface for MacroAI

import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showPermissionAlert = false
    @State private var scannedBarcode: String?
    @State private var showBarcodeResult = false
    
    var onBarcodeScanned: ((String) -> Void)?
    
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
                        .onAppear {
                            cameraManager.startSession()
                            startBarcodeScanning()
                        }
                        .onDisappear {
                            cameraManager.stopSession()
                            cameraManager.stopBarcodeScanning()
                        }
                    
                    // Barcode Scanning Overlay
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
                            
                            // Scanning Status
                            if cameraManager.isBarcodeScanning {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.accentColor))
                                        .scaleEffect(0.8)
                                    Text("Scanning...")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(themeManager.primaryColor.opacity(0.8))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top, geometry.safeAreaInsets.top)
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Barcode Scanning Frame
                        VStack(spacing: 20) {
                            // Scanning Frame
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeManager.accentColor, lineWidth: 3)
                                .frame(width: 250, height: 150)
                                .overlay(
                                    VStack {
                                        Image(systemName: "barcode.viewfinder")
                                            .font(.system(size: 40))
                                            .foregroundColor(themeManager.accentColor)
                                        Text("Position barcode in frame")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                    }
                                )
                            
                            // Instructions
                            VStack(spacing: 8) {
                                Text("Point camera at any barcode")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Supports: UPC, EAN, QR, Code 128, and more")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 32)
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                    }
                } else {
                    // Permission Request
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Camera Access Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Please allow camera access to scan barcodes")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button("Grant Permission") {
                            cameraManager.requestPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(themeManager.accentColor)
                    }
                }
            }
        }
        .alert("Camera Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable camera access in Settings to scan barcodes.")
        }
        .onReceive(cameraManager.$permissionDenied) { denied in
            if denied {
                showPermissionAlert = true
            }
        }
        .onReceive(cameraManager.$detectedBarcode) { barcode in
            if let barcode = barcode {
                handleBarcodeDetected(barcode)
            }
        }
    }
    
    private func startBarcodeScanning() {
        print("🔍 [BarcodeScannerView] Starting barcode scanning...")
        cameraManager.startBarcodeScanning { barcode in
            if let barcode = barcode {
                print("🔍 [BarcodeScannerView] Received barcode from camera manager: \(barcode)")
                handleBarcodeDetected(barcode)
            } else {
                print("❌ [BarcodeScannerView] No barcode received from camera manager")
            }
        }
    }
    
    private func handleBarcodeDetected(_ barcode: String) {
        print("🔍 [BarcodeScannerView] Barcode detected: \(barcode)")
        scannedBarcode = barcode
        showBarcodeResult = true
        
        // Call the completion handler
        onBarcodeScanned?(barcode)
        print("✅ [BarcodeScannerView] Called completion handler with barcode: \(barcode)")
        
        // Dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Store the preview layer in the context coordinator for later access
        context.coordinator.previewLayer = previewLayer
        
        print("🔍 CameraPreviewView: Created preview layer")
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the frame when the view bounds change
        context.coordinator.updateFrame(for: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        func updateFrame(for view: UIView) {
            guard let previewLayer = previewLayer else { return }
            
            // Use async to ensure the view has been laid out
            DispatchQueue.main.async {
                let bounds = view.bounds
                if bounds.width > 0 && bounds.height > 0 {
                    previewLayer.frame = bounds
                    print("🔍 CameraPreviewView: Updated preview layer frame: \(bounds)")
                }
            }
        }
    }
} 