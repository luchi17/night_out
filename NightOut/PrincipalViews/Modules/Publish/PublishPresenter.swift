import SwiftUI
import Combine
import FirebaseStorage
import FirebaseDatabase
import CoreLocation
import FirebaseFirestore


final class PublishViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
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
                Task {
                    await presenter.uploadImage()
                }
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
                    description: "El club seleccionado ha sido \(club.name).",
                    image: nil
                )
                )
            }
            .store(in: &cancellables)
        
    }
    
    @MainActor //to publish changes on view in an async function
    func uploadImage() async {
        guard let image = viewModel.capturedImage else {
            return
        }
        
        guard !viewModel.description.isEmpty else {
            viewModel.toast = .custom(.init(
                title: "",
                description: "Por favor, escribe una descripción.",
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
            let fileName = "\(Int64(Date().timeIntervalSince1970)).jpg"
            let fileRef = Storage.storage().reference().child("Post Pictures").child(fileName)
            
            print("fileRef")
            print(fileRef)
            // Subir la imagen
            _ = try await fileRef.putDataAsync(imageData)
            
            // Obtener URL de descarga
            let url = try await fileRef.downloadURL()
            let imageUrl = url.absoluteString
            
            // Crear post en Firestore
            guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
            let postsRef = FirebaseServiceImpl.shared.getPosts()
            let postId = postsRef.childByAutoId().key ?? UUID().uuidString
            
            let postModel = PostUserModel(
                description: viewModel.description.lowercased(),
                postID: postId,
                postImage: imageUrl,
                publisherId: userId,
                location: viewModel.location ?? "",
                isFromUser: FirebaseServiceImpl.shared.getImUser()
            )
            print("imageUrl")
            print(imageUrl)
            
            guard let postData = structToDictionary(postModel) else {
                print("Error transforming data to json")
                return
            }
            
            try await postsRef.child(postId).setValue(postData)
            
            // Verificar si hay un rankingEmoji antes de actualizar el contador de drinks
            if viewModel.emojiSelected != nil {
                await updateDrinksForUser(userId: userId)
            }
            
        } catch {
            print("Error uploading image: \(error.localizedDescription)")
        }
    }
    
    private func updateDrinksForUser(userId: String) async {
        
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return
        }
        
        // Aumentar MisCopas en userModel
        let copasRef = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userId).child("MisCopas")
        
        do {
                try await copasRef.runTransactionBlock { currentData in
                    var currentValue = currentData.value as? Int ?? 0
                    currentValue += 1
                    currentData.value = currentValue
                    return .success(withValue: currentData)
                }
                print("MisCopas actualizado correctamente")
            } catch {
                print("Error al actualizar MisCopas: \(error.localizedDescription)")
            }

        // Cargar las ligas del usuario
        let userLeagues = FirebaseServiceImpl.shared.getUsers().child(userId).child("misLigas")
        
        userLeagues.observeSingleEvent(of: .value) { snapshot in
            
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
                        }
                    }
                }
            }
        }
    }
}
