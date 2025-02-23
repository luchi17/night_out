import SwiftUI
import AVKit
import Firebase
import FirebaseStorage
import FirebaseFirestore
import Combine

class VideoShareViewModel: ObservableObject {
    private let firestore = Firestore.firestore()
    private let storage = Storage.storage()
    private let rrssRef = Database.database().reference().child("rrss")
    private let storageRef = Storage.storage().reference().child("videos")
    
    @Published var videoUrl: URL?
    @Published var isProgressBarVisible: Bool = false
    @Published var toast: ToastType?
    
    @Published var openPicker: Bool = false
    @Published var showPermissionAlert: Bool = false
    
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
        self.videoUrl = nil
    }
    
    func applyButtonPressAnimation() {
        // Animación de presión del botón
    }
    
    func checkPermissionsAndOpenPicker() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            openPicker = true  // Permiso concedido, abrir picker
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
            showPermissionAlert = true  // Mostrar alerta para abrir Configuración
        @unknown default:
            break
        }
    }
}

struct ShareVideoView: View {
    
    @ObservedObject private var viewModel = VideoShareViewModel()
    @State private var videoPlayer: AVPlayer?
    
    @State private var selectedItem: PhotosPickerItem?
    
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
                
                if let videoUrl = viewModel.videoUrl {
                    ZStack(alignment: .topTrailing) {
                        VideoPlayer(player: videoPlayer)
                            .frame(height: 350)
                            .cornerRadius(8)
                            .onAppear {
                                videoPlayer = AVPlayer(url: videoUrl)
                                videoPlayer?.play()
                            }
                        
                        Button(action: {
                            videoPlayer?.pause()
                            viewModel.deleteVideo()
                        }) {
                            Image(systemName: "xmark") // Icono de cerrar estándar
                                .font(.system(size: 25, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
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
            
            bottomView()
            
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onChange(of: viewModel.videoUrl) { old, new in
            if let videoUrl = viewModel.videoUrl {
                videoPlayer = AVPlayer(url: videoUrl)
            }
        }
        .sheet(isPresented: $viewModel.openPicker) {
            VideoPicker(
                videoURL: $viewModel.videoUrl)
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
        .padding(.bottom, 8)
    }
}
