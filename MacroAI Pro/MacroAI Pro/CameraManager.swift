// CameraManager.swift
// Camera session manager for MacroAI food scanning and barcode detection

import Foundation
@preconcurrency import AVFoundation
import UIKit
@preconcurrency import Vision
internal import Combine

@MainActor
class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var isAuthorized = false
    @Published var permissionDenied = false
    @Published var isCapturing = false
    @Published var captureError: String?
    @Published var detectedBarcode: String?
    @Published var isBarcodeScanning = false
    @Published var barcodeScanningMode = false
    @Published var isStartingSession = false
    
    // These need to be nonisolated to be accessed from background queues
    nonisolated let captureSession = AVCaptureSession()
    nonisolated private let photoOutput = AVCapturePhotoOutput()
    nonisolated private let videoDataOutput = AVCaptureVideoDataOutput()
    nonisolated(unsafe) private var currentCameraDevice: AVCaptureDevice?
    nonisolated(unsafe) private var currentCameraInput: AVCaptureDeviceInput?
    private var photoCompletion: ((UIImage?) -> Void)?
    private var barcodeCompletion: ((String?) -> Void)?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let barcodeQueue = DispatchQueue(label: "barcode.processing.queue")
    
    // Vision framework for barcode detection
    private var barcodeDetectionRequest: VNDetectBarcodesRequest?
    private var barcodeDetectionSequence: VNSequenceRequestHandler?
    
    override init() {
        super.init()
        configureCaptureSession()
        setupBarcodeDetection()
        
        // Check initial permission status
        checkPermissionStatus()
    }
    
    // MARK: - Barcode Detection Setup
    
    private func setupBarcodeDetection() {
        barcodeDetectionRequest = VNDetectBarcodesRequest { [weak self] request, error in
            self?.handleBarcodeDetection(request: request, error: error)
        }
        
        // Configure barcode detection for common formats
        barcodeDetectionRequest?.symbologies = [
            .ean8,
            .ean13,
            .upce,
            .code39,
            .code93,
            .code128,
            .itf14,
            .pdf417,
            .qr,
            .aztec,
            .dataMatrix
        ]
        
        barcodeDetectionSequence = VNSequenceRequestHandler()
    }
    
    // MARK: - Barcode Detection Methods
    
    func startBarcodeScanning(completion: @escaping (String?) -> Void) {
        print("🔍 CameraManager: Starting barcode scanning...")
        barcodeCompletion = completion
        isBarcodeScanning = true
        barcodeScanningMode = true
        detectedBarcode = nil
        print("✅ CameraManager: Barcode scanning started")
    }
    
    func stopBarcodeScanning() {
        isBarcodeScanning = false
        barcodeScanningMode = false
        barcodeCompletion = nil
    }
    
    func processFrameForBarcode(_ image: CVPixelBuffer) {
        guard isBarcodeScanning,
              let request = barcodeDetectionRequest,
              let sequence = barcodeDetectionSequence else { 
            print("🔍 CameraManager: Barcode scanning not ready - isScanning: \(isBarcodeScanning), request: \(barcodeDetectionRequest != nil), sequence: \(barcodeDetectionSequence != nil)")
            return 
        }
        
        barcodeQueue.async {
            do {
                try sequence.perform([request], on: image)
            } catch {
                print("❌ CameraManager: Barcode detection error: \(error)")
            }
        }
    }
    
    private func handleBarcodeDetection(request: VNRequest, error: Error?) {
        if let error = error {
            print("❌ CameraManager: Barcode detection error: \(error)")
            return
        }
        
        guard let results = request.results as? [VNBarcodeObservation],
              let firstBarcode = results.first,
              let payload = firstBarcode.payloadStringValue else {
            print("🔍 CameraManager: No barcode detected in frame")
            return
        }
        
        // Only process if we're in barcode scanning mode
        guard isBarcodeScanning else { 
            print("🔍 CameraManager: Barcode scanning not active, ignoring detection")
            return 
        }
        
        DispatchQueue.main.async { @MainActor in
            self.detectedBarcode = payload
            self.isBarcodeScanning = false
            self.barcodeScanningMode = false
            self.barcodeCompletion?(payload)
            print("✅ CameraManager: Barcode detected: \(payload)")
        }
    }
    
    // MARK: - Permission Handling
    
    private func checkPermissionStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("✅ CameraManager: Camera already authorized")
            isAuthorized = true
            permissionDenied = false
            // Start session immediately when already authorized
            startSession()
        case .notDetermined:
            print("🔍 CameraManager: Camera permission not determined")
            isAuthorized = false
            permissionDenied = false
        case .denied, .restricted:
            print("❌ CameraManager: Camera permission denied or restricted")
            isAuthorized = false
            permissionDenied = true
        @unknown default:
            print("❌ CameraManager: Unknown camera permission status")
            isAuthorized = false
            permissionDenied = true
        }
    }
    
    func requestPermission() {
        print("🔍 CameraManager: Requesting camera permission...")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("✅ CameraManager: Camera already authorized")
            isAuthorized = true
            permissionDenied = false
            // Start session immediately when already authorized
            startSession()
        case .notDetermined:
            print("🔍 CameraManager: Camera permission not determined, requesting...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    print("🔍 CameraManager: Permission request result: \(granted)")
                    self?.isAuthorized = granted
                    self?.permissionDenied = !granted
                    if granted {
                        self?.startSession()
                    }
                }
            }
        case .denied, .restricted:
            print("❌ CameraManager: Camera permission denied or restricted")
            isAuthorized = false
            permissionDenied = true
        @unknown default:
            print("❌ CameraManager: Unknown camera permission status")
            isAuthorized = false
            permissionDenied = true
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Process frame for barcode detection if in barcode scanning mode
        // We need to check the barcode scanning state on the main actor
        Task { @MainActor in
            if self.isBarcodeScanning {
                guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                self.processFrameForBarcode(pixelBuffer)
            }
        }
    }
    
    // MARK: - Session Management
    
    nonisolated private func configureCaptureSession(completion: @escaping () -> Void = {}) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check if session is already configured
            if !self.captureSession.inputs.isEmpty && !self.captureSession.outputs.isEmpty {
                print("ℹ️ CameraManager: Session already configured, skipping configuration")
                completion()
                return
            }
            
            print("🔍 CameraManager: Configuring capture session...")
            
            self.captureSession.beginConfiguration()
            
            // Configure session preset for high quality photos
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }
            
            // Add camera input
            self.addCameraInput()
            
            // Add video data output for preview
            if self.captureSession.canAddOutput(self.videoDataOutput) {
                self.captureSession.addOutput(self.videoDataOutput)
                self.videoDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                print("✅ CameraManager: Video data output added")
            }
            
            // Add photo output
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
                self.configurePhotoOutput()
            }
            
            self.captureSession.commitConfiguration()
            
            print("✅ CameraManager: Capture session configured successfully")
            completion()
        }
    }
    
    nonisolated private func addCameraInput() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                  for: .video, 
                                                  position: .back) else {
            print("❌ CameraManager: No back camera available")
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
                currentCameraDevice = camera
                currentCameraInput = cameraInput
            }
        } catch {
            print("❌ CameraManager: Failed to create camera input: \(error)")
            DispatchQueue.main.async { @MainActor in
                self.captureError = "Failed to access camera: \(error.localizedDescription)"
            }
        }
    }
    
    nonisolated private func configurePhotoOutput() {
        // Use maxPhotoDimensions instead of deprecated isHighResolutionCaptureEnabled
        let maxDimensions = CMVideoDimensions(width: 4032, height: 3024) // High resolution
        photoOutput.maxPhotoDimensions = maxDimensions
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        // Configure for optimal food photography
        if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            photoOutput.setPreparedPhotoSettingsArray([
                AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            ])
        }
    }
    
    func startSession() {
        print("🔍 CameraManager: startSession called, isAuthorized: \(isAuthorized)")
        guard isAuthorized else { 
            print("❌ CameraManager: Not authorized, cannot start session")
            return 
        }
        
        // Prevent multiple simultaneous session starts
        guard !isStartingSession else { 
            print("ℹ️ CameraManager: Session start already in progress")
            return 
        }
        isStartingSession = true
        
        // Only configure and start if not already running
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                print("ℹ️ CameraManager: Session already running")
                DispatchQueue.main.async {
                    self.isStartingSession = false
                }
                return
            }
            
            // Configure session first, then start it
            self.configureCaptureSession {
                print("🔍 CameraManager: Starting session on background queue")
                
                // Ensure session is configured before starting
                if !self.captureSession.isRunning {
                    print("✅ CameraManager: Session starting...")
                    self.captureSession.startRunning()
                    print("✅ CameraManager: Session started successfully")
                } else {
                    print("ℹ️ CameraManager: Session already running")
                }
                
                // Reset the starting flag
                DispatchQueue.main.async {
                    self.isStartingSession = false
                }
            }
        }
    }
    
    func stopSession() {
        print("🔍 CameraManager: stopSession called")
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                print("🛑 CameraManager: Stopping session...")
                self.captureSession.stopRunning()
                print("🛑 CameraManager: Session stopped")
            }
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard !isCapturing else { return }
        isCapturing = true
        photoCompletion = completion

        // Capture needed state from photoOutput on the main actor
        let availableCodecTypes = photoOutput.availablePhotoCodecTypes
        let output = photoOutput
        let device = currentCameraDevice

        // Add stabilization delay to ensure stable image
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.sessionQueue.async { [weak self] in
                guard let self = self else { return }

                let settings: AVCapturePhotoSettings
                // Use JPEG format for food photos
                if availableCodecTypes.contains(.jpeg) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                } else {
                    settings = AVCapturePhotoSettings()
                }
                
                // Use maxPhotoDimensions instead of deprecated isHighResolutionPhotoEnabled
                let maxDimensions = CMVideoDimensions(width: 4032, height: 3024)
                settings.maxPhotoDimensions = maxDimensions

                // Configure flash based on current setting
                if let device = device, device.hasFlash {
                    settings.flashMode = device.torchMode == .on ? .on : .auto
                }
                output.capturePhoto(with: settings, delegate: self)
            }
        }
    }
    
    // MARK: - Camera Controls
    
    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            // Remove current input
            if let currentInput = self.currentCameraInput {
                self.captureSession.removeInput(currentInput)
            }
            
            // Determine new camera position
            let newPosition: AVCaptureDevice.Position = 
                self.currentCameraDevice?.position == .back ? .front : .back
            
            // Get new camera
            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                          for: .video,
                                                          position: newPosition) else {
                self.captureSession.commitConfiguration()
                return
            }
            
            // Add new input
            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.currentCameraDevice = newCamera
                    self.currentCameraInput = newInput
                }
            } catch {
                print("❌ CameraManager: Failed to flip camera: \(error)")
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    func toggleFlash(_ isOn: Bool) {
        sessionQueue.async { [weak self] in
            guard let device = self?.currentCameraDevice, device.hasFlash else { return }
            
            do {
                try device.lockForConfiguration()
                device.torchMode = isOn ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("❌ CameraManager: Failed to toggle flash: \(error)")
            }
        }
    }
    
    // MARK: - Focus and Exposure
    
    func focusAndExpose(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let device = self?.currentCameraDevice else { return }
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                
                device.unlockForConfiguration()
            } catch {
                print("❌ CameraManager: Failed to focus/expose: \(error)")
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, 
                    didFinishProcessingPhoto photo: AVCapturePhoto, 
                    error: Error?) {
        
        if let error = error {
            print("❌ CameraManager: Photo capture error: \(error)")
            DispatchQueue.main.async { @MainActor in
                self.isCapturing = false
                self.captureError = "Failed to capture photo: \(error.localizedDescription)"
                self.photoCompletion?(nil)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ CameraManager: Failed to convert photo to UIImage")
            DispatchQueue.main.async { @MainActor in
                self.isCapturing = false
                self.captureError = "Failed to process captured photo"
                self.photoCompletion?(nil)
            }
            return
        }
        
        // Optimize image for food recognition
        let optimizedImage = optimizeImageForRecognition(image)
        
        DispatchQueue.main.async { @MainActor in
            self.isCapturing = false
            print("✅ CameraManager: Photo captured successfully")
            self.photoCompletion?(optimizedImage)
        }
    }
    
    nonisolated private func optimizeImageForRecognition(_ image: UIImage) -> UIImage {
        // Resize image for optimal API performance while maintaining quality
        let maxDimension: CGFloat = 1024
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        
        if scale < 1.0 {
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage ?? image
        }
        
        return image
    }
} 

