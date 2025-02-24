import SwiftUI
import Combine
import Firebase
import FirebaseStorage
import FirebaseFirestore
import PhotosUI

class VideoShareViewModel: ObservableObject {
    
    @Published var videoUrl: URL?
    @Published var isProgressBarVisible: Bool = false
    @Published var toast: ToastType?
    
    @Published var openPicker: Bool = false
    @Published var showPermissionAlert: Bool = false
    
    @Published var selectedItem: PhotosPickerItem?
    @Published var loadingVideo: Bool = false
    @Published var shouldResetVideoPlayer: Bool = false
    
}

protocol ShareVideoPresenter {
    var viewModel: VideoShareViewModel { get }
    func transform(input: ShareVideoPresenterImpl.ViewInputs)
}

final class ShareVideoPresenterImpl: ShareVideoPresenter {
    
    struct ViewInputs {
        let shareVideo: AnyPublisher<Void, Never>
        let openPicker: AnyPublisher<Void, Never>
    }
    
    var viewModel: VideoShareViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    
    private let rrssRef = FirebaseServiceImpl.shared.getRrss()
    
    init() {
        viewModel = VideoShareViewModel()
    }
    
    func transform(input: ShareVideoPresenterImpl.ViewInputs) {
        
        input
            .shareVideo
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.shareVideo()
            }
            .store(in: &cancellables)
        
        input
            .openPicker
            .withUnretained(self)
            .sink { presenter, _ in
                GalleryManager.shared.checkPermissionsAndOpenPicker()
                if GalleryManager.shared.hasPermission {
                    presenter.viewModel.openPicker = true
                } else {
                    presenter.viewModel.openPicker = false
                    presenter.viewModel.showPermissionAlert = true
                }
            }
            .store(in: &cancellables)
    }
    
    func shareVideo() {
        if let uri = viewModel.videoUrl {
            checkAndUploadVideo(uri: uri)
        } else {
            viewModel.toast = .custom(.init(title: "", description: "No se ha seleccionado un video.", image: nil))
        }
    }
    
    private func checkAndUploadVideo(uri: URL) {
        // Verificar cuántos videos hay en el nodo "rrss"
        rrssRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            if snapshot.childrenCount < 100 {
                self?.uploadVideoToFirebase(uri: uri)
            } else {
                self?.viewModel.toast = .success(.init(title: "", description: "Video subido correctamente, gracias.", image: nil))
                self?.deleteVideo()
            }
        }
    }
    
    private func uploadVideoToFirebase(uri: URL) {
        viewModel.isProgressBarVisible = true

        let storageRef = Storage.storage().reference().child("videos")
        let videoRef = storageRef.child("\(Int64(Date().timeIntervalSince1970)).mp4")

        do {
            let videoData = try Data(contentsOf: uri) // Convierte el video en Data
            let uploadTask = videoRef.putData(videoData, metadata: nil)

            uploadTask.observe(.success) { [weak self] _ in
                
                guard let self = self else { return }
                
                videoRef.downloadURL { url, error in
                    guard let downloadUrl = url else {
                        self.viewModel.toast = .custom(.init(title: "", description: "Error al subir el video.", image: nil))
                        self.viewModel.isProgressBarVisible = false
                        self.deleteVideo()
                        return
                    }

                    let videoData = ["videoUrl": downloadUrl.absoluteString]
                    self.rrssRef.childByAutoId().setValue(videoData) { error, _ in
                        self.viewModel.toast = error == nil ?
                            .success(.init(title: "", description: "Video subido exitosamente.", image: nil)) :
                            .custom(.init(title: "", description: "Error al guardar los datos.", image: nil))
                        
                        self.viewModel.isProgressBarVisible = false
                        self.deleteVideo()
                    }
                }
            }

            uploadTask.observe(.failure) { [weak self] _ in
                self?.viewModel.toast = .custom(.init(title: "", description: "Error al subir el video.", image: nil))
                self?.viewModel.isProgressBarVisible = false
                self?.deleteVideo()
            }

        } catch {
            print("Error al leer el video como Data: \(error.localizedDescription)")
            self.viewModel.toast = .custom(.init(title: "", description: "Error al procesar el video.", image: nil))
            self.viewModel.isProgressBarVisible = false
            self.deleteVideo()
        }
    }
    
    private func deleteVideo() {
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.selectedItem = nil
            self?.viewModel.videoUrl = nil
            self?.viewModel.shouldResetVideoPlayer = true
        }
    }
}
