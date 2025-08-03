// CameraViewController.swift
// UIViewControllerRepresentable & coordinator for live camera and capturing images

import SwiftUI
import AVFoundation

struct CameraViewController: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onDismiss: () -> Void

    func makeCoordinator() -> CameraCoordinator {
        CameraCoordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = CameraController()
        controller.delegate = context.coordinator
        context.coordinator.cameraController = controller
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    // MARK: - Coordinator
    class CameraCoordinator: NSObject, AVCapturePhotoCaptureDelegate {
        let parent: CameraViewController
        weak var cameraController: CameraController?
        init(parent: CameraViewController) { self.parent = parent }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let data = photo.fileDataRepresentation(), let uiImage = UIImage(data: data) else { return }
            parent.image = uiImage
            parent.onDismiss()
            cameraController?.stopSession()
        }
    }
}

// MARK: - UIViewController subclass for Camera Session
class CameraController: UIViewController {
    var delegate: AVCapturePhotoCaptureDelegate?
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
        setupPreview()
        setupCaptureButton()
        session.startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    func setupSession() {
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input), session.canAddOutput(output) else { return }
        session.addInput(input)
        session.addOutput(output)
        session.commitConfiguration()
    }

    func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }

    func setupCaptureButton() {
        let buttonSize: CGFloat = 70
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        button.layer.cornerRadius = buttonSize/2
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -48),
            button.widthAnchor.constraint(equalToConstant: buttonSize),
            button.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
    }

    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: delegate!)
    }

    func stopSession() {
        if session.isRunning { session.stopRunning() }
    }
}
