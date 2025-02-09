import SwiftUI
import Combine
import FirebaseStorage
import FirebaseDatabase
import CoreLocation
import FirebaseFirestore


final class PublishViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var imageData: Data?
    @Published var description: String = ""
    @Published var location: String?
    @Published var locations: [AddPostLocationModel] = []
    
    @Published var toast: ToastType?
    
    @Published var emojiSelected: String?
    
    @Published var locationManager: LocationManager = LocationManager.shared
}

protocol PublishPresenter {
    var viewModel: PublishViewModel { get }
    func transform(input: PublishPresenterImpl.ViewInputs)
}

final class PublishPresenterImpl: PublishPresenter {
    
    struct UseCases {
    }
    
    struct Actions {
        let goToFeed: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let uploadPost: AnyPublisher<Void, Never>
        let getClubs: AnyPublisher<Void, Never>
        let myLocationTapped: AnyPublisher<Void, Never>
        let clubTapped: AnyPublisher<AddPostLocationModel, Never>
    }
    
    var viewModel: PublishViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private let storageRef = Storage.storage().reference().child("post_images")
    private let postsRef = Firestore.firestore().collection("Posts")
    
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = PublishViewModel()
        
    }
    
    func transform(input: PublishPresenterImpl.ViewInputs) {
        input
            .uploadPost
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.goToFeed() //REmove, just to check
                
                //                presenter.uploadImage()
            }
            .store(in: &cancellables)
        
        input
            .getClubs
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.viewModel.locations = UserDefaults.getCompanies()?.users.map({ data in
                    AddPostLocationModel(
                        name: data.value.username ?? "Desconocido",
                        uid: data.value.uid,
                        location: data.value.location ?? ""
                    )
                }) ?? []
            }
            .store(in: &cancellables)
        
        input
            .myLocationTapped
            .withUnretained(self)
            .sink { presenter, _ in
                let userLocation = presenter.viewModel.locationManager.userLocation
                presenter.viewModel.location = userLocation.location.latitude.description + "," + userLocation.location.longitude.description
            }
            .store(in: &cancellables)
        
        input
            .clubTapped
            .withUnretained(self)
            .sink { presenter, club in
                presenter.viewModel.location = club.location
                presenter.viewModel.toast = .success(.init(
                    title: "",
                    description: "El club seleccionado ha sido \(club.name)",
                    image: nil
                )
                )
            }
            .store(in: &cancellables)
        
    }
    
    func uploadImage() async {
        guard let image = viewModel.capturedImage else {
            viewModel.toast = .custom(.init(
                title: "",
                description: "Por favor, captura una imagen primero.",
                image: nil
            ))
            return
        }
        
        guard !viewModel.description.isEmpty else {
            viewModel.toast = .custom(.init(
                title: "",
                description: "Por favor, escribe una descripción",
                image: nil
            ))
            return
        }
        
        
        
        // Redirigir a la pantalla principal antes de subir la imagen
        actions.goToFeed()
        
        do {
            // Convertir la imagen en Data
            guard let imageData = image.jpegData(compressionQuality: 0.9) else { return }
            
            // Crear referencia de la imagen con timestamp
            let fileRef = storageRef.child("\(UUID().uuidString).jpg")
            
            // Subir la imagen
            _ = try await fileRef.putDataAsync(imageData)
            
            // Obtener URL de descarga
            let url = try await fileRef.downloadURL()
            let imageUrl = url.absoluteString
            
            // Crear post en Firestore
            guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
            let postId = postsRef.document().documentID
            
            let postModel = PostUserModel(
                description: viewModel.description.lowercased(),
                postID: postId,
                postImage: imageUrl,
                publisherId: userId,
                location: viewModel.location ?? "",
                isFromUser: FirebaseServiceImpl.shared.getImUser(),
                date: Date().toIsoString()
            )
            
            guard let postData = structToDictionary(postModel) else {
                print("Error transforming data to json")
                return
            }
            
            try await postsRef.document(postId).setData(postData)
            
            // Verificar si hay un rankingEmoji antes de actualizar el contador de drinks
            if hasRankingEmoji() {
                await updateDrinksCounter(for: userId)
            }
            
        } catch {
            print("Error uploading image: \(error.localizedDescription)")
        }
    }
    
    private func hasRankingEmoji() -> Bool {
        // Aquí deberías revisar si el emoji está presente en la UI.
        // Simulamos que siempre hay un emoji por ahora.
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return false
        }
        
        let userLeagues = FirebaseServiceImpl.shared.getUsers().child(userId).child("misLigas")
        
        userLeagues.observeSingleEvent(of: .value) { snapshot in
            // Para cada liga en la que el usuario participa, incrementa el valor de "drinks"
            
            for leagueSnapshot in snapshot.children {
                
                guard let leagueSnapshot = leagueSnapshot as? DataSnapshot else {
                    continue
                }
                
                let leagueId = leagueSnapshot.key
                // Acceder al nodo de drinks en cada liga del usuario
                let leagueDrinksRef = FirebaseServiceImpl.shared.getLeagues().child(leagueId).child("drinks").child(userId)
                
                // Leer el valor actual de drinks
                leagueDrinksRef.observeSingleEvent(of: .value) { drinksSnapshot in
                    let currentDrinks = drinksSnapshot.value as? Int ?? 0
                    
                    // Incrementar el valor de drinks en 1
                    leagueDrinksRef.setValue(currentDrinks + 1) { error, _ in
                        if let error = error {
                            // Manejar error si la actualización falla
                            print("Error al actualizar drinks: \(error.localizedDescription)")
                        } else {
                            // Actualización exitosa, aquí podrías agregar alguna notificación si es necesario
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    private func updateDrinksCounter(for userId: String) async {
        let userRef = Firestore.firestore().collection("Users").document(userId)
        
        do {
            let userSnapshot = try await userRef.getDocument()
            if let leagues = userSnapshot.data()?["misLigas"] as? [String] {
                for leagueId in leagues {
                    let leagueRef = Firestore.firestore().collection("Leagues").document(leagueId)
                        .collection("drinks").document(userId)
                    
                    let snapshot = try await leagueRef.getDocument()
                    let currentDrinks = snapshot.data()?["drinks"] as? Int ?? 0
                    
                    try await leagueRef.setData(["drinks": currentDrinks + 1], merge: true)
                }
            }
        } catch {
            print("Error updating drinks count: \(error.localizedDescription)")
        }
    }
}
