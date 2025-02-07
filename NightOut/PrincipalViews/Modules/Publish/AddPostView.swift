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
    
    @State private var showingIconsView = false
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
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showingClubsPicker) {
            AddPostClubsList(
                locations: $viewModel.locations) { companyModel in
                    viewModel.location = companyModel.location
                    showingClubsPicker.toggle()
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
        }
        .sheet(isPresented: $showingIconsView) {
            //
        }
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
        .background(Color.black.opacity(0.5))
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
        }) {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
                .padding(.all, 10)
        }
        .background(Color.black.opacity(0.5))
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
                .background(Color.black.opacity(0.5))
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
                .background(Color.black.opacity(0.5))
                .frame(width: 40, height: 40)
                .cornerRadius(10)
        }
    }
    
    var descriptionTextField: some View {
        TextField("", text: $viewModel.description, prompt: Text("Añadir descripción...").foregroundColor(.white))
            .padding(10)
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
            getMyLocation: getMyLocationPublisher.eraseToAnyPublisher()
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
