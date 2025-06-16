import SwiftUI
import AVKit
import Combine
import PhotosUI

struct ShareVideoView: View {
    
    private let shareVideoPublisher = PassthroughSubject<Void, Never>()
    private let openPickerPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject private var viewModel: VideoShareViewModel
    
    @State var videoPlayer: AVPlayer?
    
    let presenter: ShareVideoPresenter
    
    init(presenter: ShareVideoPresenter) {
        self.presenter = presenter
        self.viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            shareTitle()
            
            Spacer()
            
            ZStack {
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 3, dash: [12]))
                    .foregroundStyle(Color.grayColor)
                    .frame(height: 350)
                    .cornerRadius(8)
                
                if let player = videoPlayer {
                    
                    if viewModel.isProgressBarVisible {
                        VStack {
                            ProgressView(value: viewModel.uploadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .tint(.yellow)
                                .padding()
                            Text("\(Int(viewModel.uploadProgress * 100))% completado")
                                .foregroundStyle(Color.white)
                                .font(.caption)
                        }
                    } else {
                        VideoPlayer(player: player)
                            .frame(height: 350)
                            .cornerRadius(8)
                    }
                } else {
                    if viewModel.loadingVideo {
                        ProgressView()
                    } else {
                        Button(action: {
                            openPickerPublisher.send()
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
        .padding([.horizontal, .bottom])
        .background(Color.blackColor.edgesIgnoringSafeArea(.all))
        .photosPicker(isPresented: $viewModel.openPicker, selection: $viewModel.selectedItem, matching: .videos)
        .onChange(of: viewModel.selectedItem) {
            Task {
                if let selectedItem = viewModel.selectedItem {
                    self.viewModel.loadingVideo = true
                    
                    if let movie = try await selectedItem.loadTransferable(type: Movie.self) {
                        self.viewModel.loadingVideo = false
                        self.viewModel.videoUrl = movie.url
                        self.videoPlayer = AVPlayer(url: movie.url)
                        self.videoPlayer?.play()
                    }
                }
            }
        }
        .onChange(of: viewModel.shouldResetVideoPlayer) {
            if viewModel.shouldResetVideoPlayer {
                self.resetVideoPlayer()
            }
        }
        .showGalleryPermissionAlert(show: $viewModel.showPermissionAlert)
        .showToast(
            error: (
                type: viewModel.toast,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toast = nil
                }
            ),
            isIdle: false,
            extraPadding: .none,
            showAnimation: false
        )
    }
    
    private func shareTitle() -> some View {
        Text("Comparte tu video y podrás salir en nuestras redes sociales.")
            .font(.system(size: 18, weight: .regular))
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 10)
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
            
            Spacer()
            
            HStack(spacing: 10) {
                Spacer()
                
                Button(action: {
                    videoPlayer?.pause()
                    shareVideoPublisher.send()
                }) {
                    Text("Compartir video".uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Color.grayColor)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                .opacity(viewModel.isProgressBarVisible ? 0.5 : 1)
                .disabled(viewModel.isProgressBarVisible)
                
                Button(action: {
                    videoPlayer?.pause()
                    resetVideoPlayer()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
            }
            .padding(.top)
            
            Spacer()
            
            VStack(spacing: 0) {
                socialMediaRow(iconName: "instagram_icon", platformName: "Instagram")
                    .onTapGesture {
                        abrirInstagram()
                    }
                socialMediaRow(iconName: "tiktok_icon", platformName: "TikTok")
                    .onTapGesture {
                        abrirTikTok()
                    }
            }
        }
    }
    
    func resetVideoPlayer() {
        print("resetVideoPlayer")
        videoPlayer?.pause()
        viewModel.videoUrl = nil
        viewModel.selectedItem = nil
        viewModel.loadingVideo = false
        videoPlayer = nil
    }
    
    func abrirTikTok() {
        // Intenta abrir la app de TikTok directamente
        let urlApp = URL(string: "tiktok://user/@nocheeo")!
        let webURL = URL(string: "https://www.tiktok.com/@nocheeo")!
        
        if UIApplication.shared.canOpenURL(urlApp) {
            UIApplication.shared.open(urlApp, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }

    func abrirInstagram() {
        let username = "nocheeo"
        let appURL = URL(string: "instagram://user?username=\(username)")!
        let webURL = URL(string: "https://instagram.com/\(username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")")!

        
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
}

private extension ShareVideoView {
    func bindViewModel() {
        let input = ShareVideoPresenterImpl.ViewInputs(
            shareVideo: shareVideoPublisher.eraseToAnyPublisher(),
            openPicker: openPickerPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

