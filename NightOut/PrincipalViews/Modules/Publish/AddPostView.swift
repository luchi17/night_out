import SwiftUI
import Combine
import FirebaseStorage
import FirebaseDatabase
import CoreLocation

struct AddPostView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let uploadPostPublisher = PassthroughSubject<Void, Never>()
    private let getClubsPublisher = PassthroughSubject<Void, Never>()
    private let getMyLocationPublisher = PassthroughSubject<Void, Never>()
    private let clubTappedPublisher = PassthroughSubject<AddPostLocationModel, Never>()
    
    @State private var showingIconsView = false
    @State private var emojiPosition: CGSize = .zero
    @State private var initialPosition: CGSize = .zero
    
    @State private var showingLocationAlert = false
    
    @State private var showingClubsPicker = false
    @State private var showingMyLocation = false
    
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
    @ObservedObject var viewModel: PublishViewModel
    
    @StateObject var cameraModel = CameraViewModel()
    
    let presenter: PublishPresenter
    
    init(
        presenter: PublishPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                if viewModel.capturedImage == nil {
                    CameraPreview(session: cameraModel.session)
                    
                    notCapturedImageButtonsView
                    
                } else if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    
                    capturedImageButtonsView
                    
                    if let emoji = viewModel.emojiSelected {
                        Image(emoji)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .position(x: initialPosition.width + emojiPosition.width + 100,
                                      y: initialPosition.height + emojiPosition.height + 200)
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        emojiPosition = gesture.translation
                                    }
                                    .onEnded { _ in
                                        initialPosition.width += emojiPosition.width
                                        initialPosition.height += emojiPosition.height
                                        emojiPosition = .zero
                                    }
                            )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.light)
        .sheet(isPresented: $showingClubsPicker) {
            AddPostClubsList(
                locations: $viewModel.locations,
                onLocationSelected: { club in
                    showingClubsPicker = false
                    clubTappedPublisher.send(club)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .background(Color.white.ignoresSafeArea())
        }
        .sheet(isPresented: $showingLocationAlert) {
            ClubSelectionAlert(onTypeSelected: { type in
                switch type {
                case .clubs:
                    getClubsPublisher.send()
                    showingClubsPicker.toggle()
                    showingLocationAlert.toggle()
                case .myLocation:
                    getMyLocationPublisher.send()
                    showingLocationAlert.toggle()
                }
            })
            .presentationDetents([.fraction(0.2)])
            .presentationDragIndicator(.visible)
            .background(Color.white.ignoresSafeArea())
        }
        .sheet(isPresented: $showingIconsView) {
            IconsView { emoji in
                viewModel.emojiSelected = emoji
                initialPosition = .zero // Resetea la posición
                emojiPosition = .zero // Resetea la posición
                showingIconsView.toggle()
            }
            .presentationDetents([.fraction(0.3)])
            .presentationDragIndicator(.visible)
            .background(Color.white.ignoresSafeArea())
        }
        .alert(isPresented: $viewModel.locationManager.locationPermissionDenied) {
            Alert(
                title: Text("Permisos de Localización Denegados"),
                message: Text("Por favor, habilita los permisos de localización en los ajustes para poder usar tu ubicación."),
                primaryButton: .default(Text("Abrir Ajustes"), action: {
                    if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettings)
                    }
                }),
                secondaryButton: .cancel()
            )
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
            extraPadding: .large
        )
        .onAppear {
            cameraModel.startSession()
        }
        .onDisappear {
            cameraModel.stopSession()
        }
        .onTapGesture {
            // Cerrar el teclado cuando tocas fuera de él
            hideKeyboard()
        }
    }
    
    var capturedImageButtonsView: some View {
        VStack {
            HStack {
                Spacer()
                
                locationView
                
                Spacer()
                
                iconsView
                
                Spacer()
            }
            .safeAreaPadding(.top)
            .padding(.top, 50)
            
            Spacer()
            
            descriptionTextField
                .padding(.bottom, keyboardObserver.keyboardHeight == 0 ? 35 : keyboardObserver.keyboardHeight)
                .animation(.easeOut(duration: 0.2), value: keyboardObserver.keyboardHeight)
            
            ZStack(alignment: .bottomLeading) {
                HStack {
                    Spacer()
                    
                    sendPhotoView
                    
                    Spacer()
                }
                .padding(.bottom, 20)
                
                cancelPhotoView
                    .padding(.leading, 20)
                    .padding(.bottom, 30)
            }
        }
    }
    
    var notCapturedImageButtonsView: some View {
        VStack {
            Spacer()
            
            ZStack(alignment: .bottomLeading) {
                HStack {
                    Spacer()
                    
                    capturePhotoView
                    
                    Spacer()
                }
                
                switchCameraView
                    .padding(.leading, 20)
            }
        }
        .padding(.bottom, 30)
    }
    
    var switchCameraView: some View {
        Button(action: {
            cameraModel.switchCamera()
        }) {
            Image(systemName: "arrow.triangle.2.circlepath.camera")
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
                .foregroundColor(.white)
                .padding(.all, 8)
        }
        .background(Color.blackColor.opacity(0.5))
        .clipShape(Circle())
        .padding(.leading, 20)
    }
    
    var capturePhotoView: some View {
        Button(action: {
            cameraModel.capturePhoto { image in
                viewModel.capturedImage = image
            }
        }) {
            Circle()
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 50, height: 50)
        }
    }
    
    var cancelPhotoView: some View {
        Button(action: {
            viewModel.capturedImage = nil
            viewModel.description = ""
            viewModel.location = ""
            viewModel.emojiSelected = nil
        }) {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
                .padding(.all, 10)
        }
        .background(Color.blackColor.opacity(0.5))
        .cornerRadius(10)
        .padding(.leading, 20)
    }
    
    var sendPhotoView: some View {
        Button(action: {
            uploadPostPublisher.send()
        }) {
            Image(systemName: "paperplane.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
                .padding()
        }
    }
    
    var locationView: some View {
        Button(action: {
            showingLocationAlert.toggle()
        }) {
            Text("📍")
                .font(.subheadline) // Tamaño del emoji
                .padding()
                .background(Color.blackColor.opacity(0.5))
                .frame(width: 40, height: 40)
                .clipShape(Rectangle())
                .cornerRadius(10)
        }
    }
    
    var iconsView: some View {
        Button(action: {
            showingIconsView.toggle()
        }) {
            Image("trofeo")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding()
                .foregroundColor(.white)
                .background(Color.blackColor.opacity(0.5))
                .frame(width: 40, height: 40)
                .cornerRadius(10)
        }
    }
    
    var descriptionTextField: some View {
        TextField("", text: $viewModel.description, prompt: Text("Añadir descripción...").foregroundColor(.white))
            .padding(.leading, 20)
            .foregroundColor(.white) // Color del texto
            .accentColor(.white)
    }
}

private extension AddPostView {
    func bindViewModel() {
        let input = PublishPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            uploadPost: uploadPostPublisher.eraseToAnyPublisher(),
            getClubs: getClubsPublisher.eraseToAnyPublisher(),
            myLocationTapped: getMyLocationPublisher.eraseToAnyPublisher(),
            clubTapped: clubTappedPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}



//flash:
//
//class CameraViewModel: NSObject, ObservableObject {
//    let session = AVCaptureSession()
//    private var photoOutput = AVCapturePhotoOutput()
//    private var currentDevice: AVCaptureDevice?
//    private var isUsingFrontCamera = false
//    private var captureCompletion: ((UIImage?) -> Void)?
//
//    @Published var isFlashOn = false // 🔦 Estado del flash
//
//    override init() {
//        super.init()
//        configureCamera()
//    }
//
//    func toggleFlash() {
//        isFlashOn.toggle()
//    }
//
//    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
//        let settings = AVCapturePhotoSettings()
//        settings.flashMode = isFlashOn ? .on : .off
//        captureCompletion = completion
//        photoOutput.capturePhoto(with: settings, delegate: self)
//    }
//}
//
