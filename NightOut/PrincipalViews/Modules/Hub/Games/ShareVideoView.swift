import SwiftUI
import AVKit
import Firebase
import FirebaseStorage
import FirebaseFirestore
import Combine

import PhotosUI

class VideoShareViewModel: ObservableObject {
    
    private let rrssRef = FirebaseServiceImpl.shared.getRrss()
    
    @Published var videoUrl: URL?
    @Published var isProgressBarVisible: Bool = false
    @Published var toast: ToastType?
    
    @Published var openPicker: Bool = false
    @Published var showPermissionAlert: Bool = false
    
    @Published var selectedItem: PhotosPickerItem?
    @Published var loadingVideo: Bool = false
    @Published var shouldResetVideoPlayer: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func shareVideo() {
        if let uri = videoUrl {
            checkAndUploadVideo(uri: uri)
        } else {
            self.toast = .custom(.init(title: "", description: "No se ha seleccionado un video.", image: nil))
        }
    }
    
    func checkAndUploadVideo(uri: URL) {
        // Verificar cuántos videos hay en el nodo "rrss"
        rrssRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.childrenCount < 100 {
                self.uploadVideoToFirebase(uri: uri)
            } else {
                self.toast = .success(.init(title: "", description: "Video subido correctamente, gracias.", image: nil))
                self.deleteVideo()
            }
        }
    }
    
    private func uploadVideoToFirebase(uri: URL) {
        
        isProgressBarVisible = true
        
        let storageRef = Storage.storage().reference().child("videos")
        let videoRef = storageRef.child("\(Int64(Date().timeIntervalSince1970)).mp4")
        
        let uploadTask = videoRef.putFile(from: uri, metadata: nil)
        
        uploadTask.observe(.success) { _ in
            videoRef.downloadURL { url, error in
                guard let downloadUrl = url else {
                    self.toast = .custom(.init(title: "", description: "Error al subir el video.", image: nil))
                    self.isProgressBarVisible = false
                    return
                }
                
                let videoData = ["videoUrl": downloadUrl.absoluteString]
                self.rrssRef.childByAutoId().setValue(videoData) { error, _ in
                    if error != nil {
                        self.toast = .custom(.init(title: "", description: "Error al guardar los datos en la base de datos.", image: nil))
                    } else {
                        self.toast = .success(.init(title: "", description: "Video subido exitosamente, gracias.", image: nil))
                        self.deleteVideo()
                    }
                    self.isProgressBarVisible = false
                }
            }
        }
        
        uploadTask.observe(.failure) { _ in
            self.toast = .custom(.init(title: "", description: "Error al subir el video.", image: nil))
            self.isProgressBarVisible = false
        }
    }
    
    func deleteVideo() {
        shouldResetVideoPlayer = true
    }
    
    func checkPermissionsAndOpenPicker() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            openPicker = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.openPicker = true
                    } else {
                        self?.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
}

struct ShareVideoView: View {
    
    @ObservedObject private var viewModel: VideoShareViewModel
    
    @State var videoPlayer: AVPlayer?
    
    init(viewModel: VideoShareViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            shareTitle()
            
            Spacer()
            
            ZStack {
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 3, dash: [12]))
                    .foregroundStyle(.gray)
                    .frame(height: 350)
                    .cornerRadius(8)
                
                if let player = videoPlayer {
                    VideoPlayer(player: player)
                        .frame(height: 350)
                        .cornerRadius(8)
                } else {
                    if viewModel.loadingVideo {
                        ProgressView()
                    } else {
                        Button(action: {
                            viewModel.checkPermissionsAndOpenPicker()
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(lineWidth: 2)
                                    .foregroundStyle(.white)
                                    .frame(width: 45, height: 45)
                                    .shadow(radius: 4)
                                
                                Image(systemName: "plus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                }
            }
            
            bottomView()
            
        }
        .padding()
        .background(Color.blackColor.edgesIgnoringSafeArea(.all))
        .photosPicker(isPresented: $viewModel.openPicker, selection: $viewModel.selectedItem, matching: .videos)
        .onChange(of: viewModel.selectedItem) {
            Task {
                self.viewModel.loadingVideo = true
                if let movie = try await viewModel.selectedItem?.loadTransferable(type: Movie.self) {
                    self.viewModel.loadingVideo = false
                    self.viewModel.videoUrl = movie.url
                    self.videoPlayer = AVPlayer(url: movie.url)
                    self.videoPlayer?.play()
                }
            }
        }
        .onChange(of: viewModel.shouldResetVideoPlayer) {
            if viewModel.shouldResetVideoPlayer {
                self.resetVideoPlayer()
            }
        }
        .alert("Permiso requerido", isPresented: $viewModel.showPermissionAlert) {
            Button("Abrir Configuración") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Esta aplicación necesita acceso a tu galería para seleccionar videos.")
        }
        .showToast(
            error: (
                type: viewModel.toast,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toast = nil
                }
            ),
            isIdle: false,
            extraPadding: .none
        )
    }
    
    private func shareTitle() -> some View {
        Text("Comparte tu video y podrás salir en nuestras redes sociales.")
            .font(.system(size: 19, weight: .regular))
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 10)
    }
    
    
    private func socialMediaRow(iconName: String, platformName: String) -> some View {
        HStack {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.white)
            
            Text(platformName)
                .foregroundColor(.white)
                .font(.subheadline)
            
            Spacer()
        }
        .padding(.bottom, 2)
    }
    
    private func bottomView() -> some View {
        VStack {
            
            // Progress bar visibility
            if viewModel.isProgressBarVisible {
                ProgressView("Uploading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
                    .padding()
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Spacer()
                
                Button(action: {
                    viewModel.shareVideo()
                }) {
                    Text("Compartir video".uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                .opacity(viewModel.isProgressBarVisible ? 0.5 : 1)
                .disabled(viewModel.isProgressBarVisible)
                
                Button(action: {
                    resetVideoPlayer()
                }) {
                    Image(systemName: "xmark") // Icono de cerrar estándar
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
            }
            
            Spacer()
            
            // Social Media Row
            VStack(spacing: 0) {
                socialMediaRow(iconName: "instagram_icon", platformName: "Instagram")
                socialMediaRow(iconName: "x_icon", platformName: "X")
                socialMediaRow(iconName: "tiktok_icon", platformName: "TikTok")
            }
        }
    }
    
    func resetVideoPlayer() {
        videoPlayer?.pause()
        viewModel.videoUrl = nil
        viewModel.selectedItem = nil
        viewModel.loadingVideo = false
        videoPlayer = nil
    }
}
