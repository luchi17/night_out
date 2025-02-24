import Foundation
import Combine
import PhotosUI

class GalleryManager: NSObject, ObservableObject {
    
    public static let shared = GalleryManager()
    
    @Published var hasPermission = false // Variable para permisos
    
     func checkPermissionsAndOpenPicker() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            hasPermission = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.hasPermission = true
                    } else {
                        self?.hasPermission = false
                    }
                }
            }
        case .denied, .restricted:
            hasPermission = false
        @unknown default:
            break
        }
    }
}
