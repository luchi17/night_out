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
            CameraPreview(session: cameraModel.session)
                .ignoresSafeArea()
                .opacity(viewModel.capturedImage == nil ? 1 : 0)
            
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.capturedImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        cameraModel.switchCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        cameraModel.capturePhoto { image in
                            viewModel.capturedImage = image
                        }
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            cameraModel.startSession()
        }
        .onDisappear {
            cameraModel.stopSession()
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
