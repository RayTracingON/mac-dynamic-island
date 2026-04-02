import Foundation
import AVFoundation
import Combine
import AppKit

/// Manager for camera operations
class CameraManager: NSObject, ObservableObject {
    static let shared = CameraManager()
    
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var capturedImage: NSImage?
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private override init() {
        super.init()
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            requestAuthorization()
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    func requestAuthorization() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
        }
    }
    
    // MARK: - Session Management
    
    func startSession() {
        guard isAuthorized else {
            requestAuthorization()
            return
        }
        
        guard captureSession == nil else { return }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Configure input
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Configure output
        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            photoOutput = output
        }
        
        session.commitConfiguration()
        
        captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()
            
            DispatchQueue.main.async {
                self?.isSessionRunning = session.isRunning
            }
        }
    }
    
    func stopSession() {
        captureSession?.stopRunning()
        captureSession = nil
        photoOutput = nil
        isSessionRunning = false
    }
    
    // MARK: - Capture
    
    func capturePhoto(completion: @escaping (Result<NSImage, Error>) -> Void) {
        guard let photoOutput = photoOutput else {
            completion(.failure(CameraError.notConfigured))
            return
        }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        // Store completion handler
        self.captureCompletion = completion
    }
    
    private var captureCompletion: ((Result<NSImage, Error>) -> Void)?
    
    // MARK: - Preview
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        
        if previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            previewLayer = layer
        }
        
        return previewLayer
    }
}

// MARK: - Photo Capture Delegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            captureCompletion?(.failure(error))
            captureCompletion = nil
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = NSImage(data: imageData) else {
            captureCompletion?(.failure(CameraError.imageCreationFailed))
            captureCompletion = nil
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
            self?.captureCompletion?(.success(image))
            self?.captureCompletion = nil
        }
    }
}

// MARK: - Errors

enum CameraError: Error {
    case notAuthorized
    case notConfigured
    case imageCreationFailed
    case captureFailed
}
