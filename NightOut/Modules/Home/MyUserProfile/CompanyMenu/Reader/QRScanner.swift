import SwiftUI
import AVFoundation

class QRScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    
    private var captureCompletion: ((String) -> Void)?
    
    func startScanning(completion: @escaping (String) -> Void) {
        captureCompletion = completion
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            print("No se pudo acceder a la cámara")
            return
        }
        
        session.addInput(videoInput)
        let metadataOutput = AVCaptureMetadataOutput()
        
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let scannedValue = metadataObject.stringValue else { return }
        
        DispatchQueue.main.async {
            self.captureCompletion?(scannedValue)
        }
    }
}

//struct CameraQRScannerPreview: UIViewControllerRepresentable {
//    let session: QRScanner
//
//    func makeUIViewController(context: Context) -> UIViewController {
//        let viewController = UIViewController()
//        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
//        previewLayer.videoGravity = .resizeAspectFill
//        previewLayer.frame = UIScreen.main.bounds
//        let previewView = UIView(frame: UIScreen.main.bounds)
//        previewView.layer.addSublayer(previewLayer)
//        viewController.view = previewView
//        return viewController
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
//}
