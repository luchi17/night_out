import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @Binding var imageData: Data?
//    @Binding var selectedImage: UIImage?
    
    var body: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .clipped()
                        
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .foregroundColor(.blue) // Color del ícono
                            .padding()
                    }
                    
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let newItem = newItem {
                            if let data = try? await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                imageData = data
                                selectedImage = uiImage
                            }
                        }
                    }
                }
                .padding()
        }
    }
}


//    // Función para subir la imagen a Firebase
//    func uploadImageToFirebase(_ image: UIImage) {
//        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
//            uploadStatus = "No se pudo convertir la imagen."
//            return
//        }
//
//        // Referencia a Firebase Storage
//        let storageRef = Storage.storage().reference()
//        let imageRef = storageRef.child("images/\(UUID().uuidString).jpg")
//
//        // Subir la imagen
//        imageRef.putData(imageData, metadata: nil) { metadata, error in
//            if let error = error {
//                uploadStatus = "Error al subir imagen: \(error.localizedDescription)"
//                return
//            }
//
//            // Obtener la URL de descarga
//            imageRef.downloadURL { url, error in
//                if let error = error {
//                    uploadStatus = "Error al obtener URL: \(error.localizedDescription)"
//                } else if let downloadURL = url {
//                    uploadStatus = "Imagen subida con éxito"
//                    // Aquí puedes guardar el `downloadURL` en Firestore o usarlo en la app.
//                    print("URL de descarga: \(downloadURL.absoluteString)")
//                }
//            }
//        }
//    }
//}
//
//
