import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseStorage

struct NewEntrada: Identifiable, Equatable {
    let id = UUID()
    var nombre: String
    var precio: String
    var aforo: String
    
    public static func == (lhs: NewEntrada, rhs: NewEntrada) -> Bool {
        return lhs.id == rhs.id
    }
}

class ManagementEventsViewModel: ObservableObject {
    @Published var eventName: String = ""
    @Published var eventDate: String = ""
    @Published var eventDescription: String = ""
    @Published var selectedMusicGenre: String = ""
    @Published var startTime: String = ""
    @Published var endTime: String = ""
    @Published var image: UIImage?
    @Published var entradas: [NewEntrada] = []
    @Published var showImagePicker: Bool = false
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    @Published var selectedItem: PhotosPickerItem?
    
    let musicGenres = ["Selecciona", "Reggaeton", "Pop", "Techno", "Jazz", "Clasica", "Latina"]
    
    func addEntrada() {
        entradas.append(NewEntrada(nombre: "", precio: "", aforo: ""))
    }
    
    func removeLastEntrada() {
        if !entradas.isEmpty {
            entradas.removeLast()
        }
    }
    
    func uploadEvent() {
        
        self.loading = true
        
        guard !eventName.isEmpty, !eventDate.isEmpty, !eventDescription.isEmpty, selectedMusicGenre != "Selecciona un género", let image = image else {
            DispatchQueue.main.async {
                self.loading = false
                self.toast = .custom(.init(title: "", description: "Por favor, completa todos los campos.", image: nil))
            }
            return
        }
        
        var additionalData: [String: [String: String]] = [:]
        
        for (index, entrada) in entradas.enumerated() {
            
            if entrada.nombre.isEmpty || entrada.precio.isEmpty || entrada.aforo.isEmpty {
                self.toast = .custom(.init(title: "", description: "Por favor, completa todos los campos para la entrada tipo \(index + 1).", image: nil))
                return
            }
            additionalData[entrada.nombre] = ["price": entrada.precio, "capacity": entrada.aforo]
        }
        
        let imageRef = Storage.storage().reference().child("event_images/\(Int64(Date().timeIntervalSince1970 * 1000)).png")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        imageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.loading = false
                    self.toast = .custom(.init(title: "", description: "Error al subir imagen: \(error.localizedDescription).", image: nil))
                }
                return
            }
            
            imageRef.downloadURL { url, error in
                
                guard let downloadURL = url?.absoluteString else {
                    DispatchQueue.main.async {
                        self.loading = false
                        self.toast = .custom(.init(title: "", description: "Error al subir imagen.", image: nil))
                    }
                    return
                }
                
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    DispatchQueue.main.async {
                        self.loading = false
                        self.toast = .custom(.init(title: "", description: "No estás autenticado. Inicia sesión para continuar.", image: nil))
                    }
                    return
                }
                
                // Referencia a Firebase Firestore
                let eventRef =
                FirebaseServiceImpl.shared
                    .getCompanyInDatabaseFrom(uid: uid)
                    .child("Entradas")
                    .child(self.eventDate)
                    .child(self.eventName)
                
                let eventData: [String: Any] = [
                    "description": self.eventDescription,
                    "image_url": downloadURL,
                    "fecha": self.eventDate,
                    "musica": self.selectedMusicGenre,
                    "start_time": self.startTime,
                    "end_time": self.endTime,
                    "types": additionalData
                ]
                
                eventRef.setValue(eventData) { error, _ in
                    DispatchQueue.main.async {
                        self.loading = false
                        if let error = error {
                            self.toast = .custom(.init(title: "", description: "Error al subir evento: \(error.localizedDescription).", image: nil))
                        } else {
                            self.toast = .success(.init(title: "", description: "Evento subido exitosamente.", image: nil))
                        }
                    }
                    
                }
            }
        }
    }
}
