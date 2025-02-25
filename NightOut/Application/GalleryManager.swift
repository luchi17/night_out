import Foundation
import Combine
import PhotosUI

class GalleryManager: NSObject, ObservableObject {
    
    public static let shared = GalleryManager()

    override init() {
        super.init()
    }
    
    func checkPermissionsAndOpenPicker(completion: @escaping (Bool) -> ()) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        completion(true)
                       
                    } else {
                        completion(false)
                       
                    }
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            break
        }
    }
}
