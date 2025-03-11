import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseDatabase

struct PublicidadView: View {
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isUploading = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Logo
                Image("logo_inicio_app")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 16)
                
                // Título
                Text("Publicidad NightOutSpain")
                    .font(.title)
                    .fontWeight(.bold)
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
                        .padding(.horizontal, 16)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 100)
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Seleccionar Imagen")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .onChange(of: selectedItem) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            selectedImage = UIImage(data: data)
                        }
                    }
                }
                
                // Botón Subir Publicidad
                Button(action: uploadAdvertisement) {
                    Text("Subir Publicidad")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .disabled(isUploading || selectedImage == nil)
                
                if isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                // Texto de información adicional
                Text("La publicidad se mostrará durante un mes en el apartado de HUB.")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
                    .frame(width: 350)
                    .padding(.bottom, 16)
            }
            .padding()
        }
    }
    
    
    private func uploadAdvertisement() {
        guard let image = selectedImage else { return }
        isUploading = true
        
        let storageRef = Storage.storage().reference().child("publicidad/\(UUID().uuidString).jpg")
        let databaseRef = Database.database().reference().child("publicidad")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            guard error == nil else {
                isUploading = false
                return
            }
            
            storageRef.downloadURL { url, error in
                guard let url = url else {
                    isUploading = false
                    return
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy"
                let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                let formattedDate = dateFormatter.string(from: futureDate!)
                
                let adData: [String: Any] = ["url": url.absoluteString, "fecha": formattedDate]
                databaseRef.childByAutoId().setValue(adData) { error, _ in
                    isUploading = false
                }
            }
        }
    }
}


