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
    let presenter: PublishPresenter
    
    init(
        presenter: PublishPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
//            if let image = viewModel.image {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 250, height: 250)
//            } else {
//                Button("Capture Photo") {
//                    showingImagePicker.toggle()
//                }
//            }
            
            if viewModel.image == nil {
                Button("Capture Photo") {
                    showingImagePicker.toggle()
                }
            }
            
            TextField("Description", text: $viewModel.description)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Choose Location") {
                showingLocationPicker.toggle()
            }
            
            Button("Post") {
                uploadPostPublisher.send()
            }
        }
        
        .sheet(isPresented: $showingImagePicker) {
//            ImagePickerView(
//                imageData: $viewModel.imageData,
//                selectedImage: $viewModel.image
//            )
        }
        .sheet(isPresented: $showingLocationPicker) {
//            LocationPicker(selectedLocation: $viewModel.location)
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

//import SwiftUI
//import UIKit
//
//// ImagePicker como un UIViewControllerRepresentable
//struct ImagePicker: UIViewControllerRepresentable {
//    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//        var parent: ImagePicker
//
//        init(parent: ImagePicker) {
//            self.parent = parent
//        }
//
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//            if let selectedImage = info[.originalImage] as? UIImage {
//                parent.selectedImage = selectedImage
//            }
//            parent.isImagePickerPresented = false
//        }
//
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            parent.isImagePickerPresented = false
//        }
//    }
//
//    @Binding var selectedImage: UIImage?
//    @Binding var isImagePickerPresented: Bool
//
//    func makeCoordinator() -> Coordinator {
//        return Coordinator(parent: self)
//    }
//
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        picker.sourceType = .photoLibrary
//        return picker
//    }
//
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
//}
//
//struct ContentView: View {
//    @State private var selectedImage: UIImage?
//    @State private var isImagePickerPresented = false
//
//    var body: some View {
//        VStack {
//            if let selectedImage = selectedImage {
//                Image(uiImage: selectedImage)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 200, height: 200)
//            }
//
//            Button("Seleccionar Imagen") {
//                isImagePickerPresented.toggle()
//            }
//            .imagePicker(isPresented: $isImagePickerPresented, selectedImage: $selectedImage)
//        }
//    }
//}
