import SwiftUI
import AVFoundation


class CameraViewModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var isUsingFrontCamera = false
    private var captureCompletion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        configureCamera()
    }
    
    private func configureCamera() {
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("No back camera available")
            session.commitConfiguration()
            return
        }
        
        session.beginConfiguration()
        
        defer {
            self.session.commitConfiguration()
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
            
            currentDevice = device
        } catch {
            print("Error setting up camera input: \(error)")
        }
        
        session.commitConfiguration()
    }
    
    func startSession() {
        guard !session.isRunning, !ProcessInfo.processInfo.environment.keys.contains("SIMULATOR_DEVICE_NAME") else {
            print("Camera not available in simulator")
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        captureCompletion = completion
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func switchCamera() {
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        
        isUsingFrontCamera.toggle()
        
        let position: AVCaptureDevice.Position = isUsingFrontCamera ? .front : .back
        
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            print("No available camera for position: \(position)")
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            }
            currentDevice = newDevice
        } catch {
            print("Error switching cameras: \(error)")
        }
        
        session.commitConfiguration()
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            captureCompletion?(nil)
            return
        }
        let image = UIImage(data: imageData)
        captureCompletion?(image)
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

