import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseDatabase

struct PublicidadView: View {
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isUploading = false
    
    @State private var toast: ToastType?
    
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.blackColor.ignoresSafeArea()
            
            VStack(spacing: 16) {
                
//                HStack {
//                    Spacer()
//                    
//                    Button(action: onClose) {
//                        Image(systemName: "xmark")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 20, height: 20)
//                            .foregroundStyle(Color.white)
//                    }
//                }
                
                // Logo
                Image("logo_inicio_app")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 16)
                    .foregroundStyle(.yellow)
                
                // Título
                Text("Publicidad NightOutSpain")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                // Dimensiones recomendadas
                Text("Dimensiones recomendadas: 200 (alto) x 1080 (ancho)")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
                
                // Texto Vista previa
                Text("Vista Previa:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Vista previa de imagen
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                        .cornerRadius(8)
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Seleccionar Imagen".uppercased())
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.grayColor)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                
                .onChange(of: selectedItem) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            selectedImage = UIImage(data: data)
                        }
                    }
                }
                
                // Botón Subir Publicidad
                Button(action: uploadAdvertisement) {
                    Text("Subir Publicidad".uppercased())
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.grayColor)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                .disabled(isUploading || selectedImage == nil)
                .overlay {
                    Group {
                        if isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                }
                
                // Texto de información adicional
                Text("La publicidad se mostrará durante un mes en el apartado de HUB.")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    
                Spacer()
            }
            .padding(.top, 30)
            .padding(.horizontal, 20)
            
        }
        .overlay(alignment: .topTrailing, content: {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.white)
            }
            .padding(.trailing, 20)
            .padding(.leading)
        })
        .showToast(
            error: (
                type: toast,
                showCloseButton: false,
                onDismiss: {
                    toast = nil
                }
            ),
            isIdle: false
        )
    }
    
    
    private func uploadAdvertisement() {
        guard let image = selectedImage else { return }
        isUploading = true
        
        let storageRef = Storage.storage().reference().child("publicidad/\(UUID().uuidString).jpg")
        let databaseRef = Database.database().reference().child("publicidad")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        storageRef.putData(imageData, metadata: metadata) { _, error in
            guard error == nil else {
                isUploading = false
                self.toast = .custom(.init(title: "", description: "Error al subir la imagen.", image: nil))
                return
            }
            
            storageRef.downloadURL { url, error in
                guard let url = url else {
                    isUploading = false
                    self.toast = .custom(.init(title: "", description: "Error al subir la imagen.", image: nil))
                    return
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy"
                let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                let formattedDate = dateFormatter.string(from: futureDate!)
                
                let adData: [String: Any] = ["url": url.absoluteString, "fecha": formattedDate]
                databaseRef.childByAutoId().setValue(adData) { error, _ in
                    isUploading = false
                    self.toast = .success(.init(title: "", description: "Publicidad subida con éxito.", image: nil))
                }
            }
        }
    }
}


