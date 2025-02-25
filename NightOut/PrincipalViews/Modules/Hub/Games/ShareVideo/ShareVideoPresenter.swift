import SwiftUI
import Combine
import Firebase
import FirebaseStorage
import FirebaseFirestore
import PhotosUI

class VideoShareViewModel: ObservableObject {
    
    @Published var videoUrl: URL?
    @Published var toast: ToastType?
    
    @Published var openPicker: Bool = false
    @Published var showPermissionAlert: Bool = false
    
    @Published var selectedItem: PhotosPickerItem?
    @Published var loadingVideo: Bool = false
    @Published var shouldResetVideoPlayer: Bool = false
    
    @Published var uploadProgress: Double = 0.0
    @Published var isProgressBarVisible: Bool = false
    
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
                GalleryManager.shared.checkPermissionsAndOpenPicker() { hasPermission in
                    presenter.viewModel.openPicker = hasPermission
                    presenter.viewModel.showPermissionAlert = !hasPermission
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

        Task {
            let storageRef = Storage.storage().reference().child("videos")
            let videoRef = storageRef.child("\(Int64(Date().timeIntervalSince1970)).mp4")

            do {
                // ⚡️ Leer el video en segundo plano para no congelar la UI
                let videoData = try await loadVideoData(from: uri)

                // 🔄 Subir el video en segundo plano sin afectar la UI
                try await uploadData(videoRef: videoRef, videoData: videoData)

                // Obtener la URL de descarga
                let downloadUrl = try await getDownloadURL(videoRef: videoRef)

                // Guardar la URL en Firebase Database
                let videoUrl = ["videoUrl": downloadUrl.absoluteString]

                try await rrssRef.childByAutoId().setValue(videoUrl)
                
                updateUIAfterUpload(success: true)

            } catch {
                
               updateUIAfterUpload(success: false)
            }
        }
    }
    
    private func updateUIAfterUpload(success: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.toast = success ?
                .success(.init(title: "", description: "Video subido exitosamente.", image: nil)) :
                .custom(.init(title: "", description: "Error al subir el video.", image: nil))
            
            self?.deleteVideo()
        }
    }

    // 📌 Cargar el video en un hilo de fondo
    private func loadVideoData(from url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try Data(contentsOf: url)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Función para subir el video con `async/await`
    private func uploadData(videoRef: StorageReference, videoData: Data) async throws {
        
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        
        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = videoRef.putData(videoData, metadata: metadata) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }

            uploadTask.observe(.progress) { [weak self] snapshot in
                let percentComplete = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
                
                self?.viewModel.uploadProgress = percentComplete
                print("Subida: \(percentComplete)% completado")
            }
        }
    }

    // MARK: - Función para obtener la URL de descarga con `async/await`
    private func getDownloadURL(videoRef: StorageReference) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            videoRef.downloadURL { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                }
            }
        }
    }
    
    private func deleteVideo() {
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.isProgressBarVisible = false
            self?.viewModel.selectedItem = nil
            self?.viewModel.videoUrl = nil
            self?.viewModel.shouldResetVideoPlayer = true
        }
    }
}
