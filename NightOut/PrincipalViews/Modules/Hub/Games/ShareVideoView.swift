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
}

struct ShareVideoView: View {
    
    @ObservedObject private var viewModel = VideoShareViewModel()
    @State private var videoPlayer: AVPlayer?
    @State private var openPicker: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Comparte tu video y podrás salir en nuestras redes sociales.")
                .font(.system(size: 19, weight: .regular))
                .foregroundColor(.white)
                .frame(height: 35)
                .padding(.top, 16)
            
            // Video container
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
                        openPicker = true
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
            
            // Progress bar visibility
            if viewModel.isProgressBarVisible {
                ProgressView("Uploading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
                    .padding()
            }
            
            Spacer()
            
            // Share button
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
            
            Spacer()
            
            // Social Media Row
            VStack(spacing: 2) {
                socialMediaRow(iconName: "instagram_icon", platformName: "Instagram")
                socialMediaRow(iconName: "x_icon", platformName: "X")
                socialMediaRow(iconName: "tiktok_icon", platformName: "TikTok")
            }
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onChange(of: viewModel.videoUrl) { old, new in
            if let videoUrl = viewModel.videoUrl {
                videoPlayer = AVPlayer(url: videoUrl)
            }
        }
        .sheet(isPresented: $openPicker) {
            VideoPickerView(
                selectedVideoURL: $viewModel.videoUrl,
                content: {
                    EmptyView()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
