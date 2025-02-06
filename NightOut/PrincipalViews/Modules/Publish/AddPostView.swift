import SwiftUI
import Combine
import FirebaseStorage
import FirebaseDatabase
import CoreLocation

struct AddPostView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let uploadPostPublisher = PassthroughSubject<Void, Never>()
    
    @State private var showingImagePicker = false
    @State private var showingLocationPicker = false
    @State private var isCameraActive = true
    @State private var hideButtons = true
    
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
            if viewModel.capturedImage == nil {
                CameraPreview(session: cameraModel.session)
                    .ignoresSafeArea()
                
                notCapturedImageButtonsView
                
            } else if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                capturedImageButtonsView
            }
        }
        .onAppear {
            cameraModel.startSession()
        }
        .onDisappear {
            cameraModel.stopSession()
        }
    }
    
    var capturedImageButtonsView: some View {
        VStack {
            Spacer()
            
            ZStack(alignment: .bottomLeading) {
                HStack {
                    Spacer()
                    
                    sendPhotoView
                    
                    Spacer()
                }
                
                cancelPhotoView
                    .padding(.leading, 20)
            }
        }
        .padding(.bottom, 30)
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
        }) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.white)
                .padding()
        }
    }
    
    var sendPhotoView: some View {
        Button(action: {
           // uploadPostPublisher.send()
        }) {
            Image(systemName: "paperplane.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.white)
                .padding()
        }
    }
}

private extension AddPostView {
    func bindViewModel() {
        let input = PublishPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            uploadPost: uploadPostPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}


//VStack {
//
//    if viewModel.image == nil {
//        Button("Capture Photo") {
//            showingImagePicker.toggle()
//        }
//    }
//    
//    TextField("Description", text: $viewModel.description)
//        .padding()
//        .textFieldStyle(RoundedBorderTextFieldStyle())
//    
//    Button("Choose Location") {
//        showingLocationPicker.toggle()
//    }
//    
//    Button("Post") {
//        uploadPostPublisher.send()
//    }
//}
//.sheet(isPresented: $showingLocationPicker) {
////            LocationPicker(selectedLocation: $viewModel.location)
//}


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
