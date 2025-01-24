import Combine
import GoogleSignIn
import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import FirebaseStorage

protocol AccountDatasource {
    func login(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError>
    func loginGoogle() -> AnyPublisher<Void, Error>
    func loginApple() -> AnyPublisher<Void, Error>
    func signup(email: String, password: String) -> AnyPublisher<Void, SignupNetworkError>
    func signupCompany(email: String, password: String) -> AnyPublisher<Void, SignupNetworkError>
    func saveUser(model: UserModel) -> AnyPublisher<Bool, Never>
    func saveCompany(model: CompanyModel) -> AnyPublisher<Bool, Never>
    func getUrlCompanyImage(imageData: Data) -> AnyPublisher<String?, Never>
    func signOut() -> AnyPublisher<Void, Error>
    func deleteAccount() -> AnyPublisher<String?, Never>
    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never>
    func getCompanyInfo(uid: String) -> AnyPublisher<CompanyModel?, Never>
}

struct AccountDatasourceImpl: AccountDatasource {
    
    func login(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError> {
        // Aquí, primero comprobamos si el email y la contraseña son válidos
        guard !email.isEmpty, !password.isEmpty else {
            return Fail(error: .invalidCredentials)
                .eraseToAnyPublisher() // Emitir un resultado sin error
        }
        
        let publisher = PassthroughSubject<Void, LoginNetworkError>()
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                // Mapeo de errores de Firebase a NetworkError
                switch AuthErrorCode(rawValue: error.code) {
                case .invalidCredential:
                    print("Las credenciales proporcionadas son inválidas o han caducado.")
                    publisher.send(completion: .failure(.invalidCredentials))
                case .userDisabled:
                    print("La cuenta del usuario ha sido deshabilitada.")
                    publisher.send(completion: .failure(.userDisabled))
                case .wrongPassword:
                    print("Contraseña incorrecta.")
                    publisher.send(completion: .failure(.wrongPassword))
                default:
                    print("Error desconocido: \(error.localizedDescription)")
                    publisher.send(completion: .failure(.unknown(error)))
                }
            } else {
                // Login exitoso
                print("Login exitoso.")
                publisher.send()
                publisher.send(completion: .finished)
            }
        }
        return publisher.eraseToAnyPublisher()
    }
    
    func loginApple() -> AnyPublisher<Void, Error> {
        return .empty()
    }
    
    func loginGoogle() -> AnyPublisher<Void, Error> {
        
        let publisher = PassthroughSubject<Void, Error>()
        
        GIDSignIn.sharedInstance.signIn(withPresenting: AppCoordinator.getRootViewController()) { signInResult, error in
            if let error = error {
                publisher.send(completion: .failure(error))
                return
            }
            
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                
                publisher.send(completion: .failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to obtain authentication tokens"])))
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    publisher.send(completion: .failure(error))
                    return
                }
                
                // El inicio de sesión fue exitoso
                publisher.send(())
                // Finaliza el publisher
                publisher.send(completion: .finished)
            }
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    func signup(email: String, password: String) -> AnyPublisher<Void, SignupNetworkError> {
        // Lógica con Firebase Auth para registrar el usuario
        let publisher = PassthroughSubject<Void, SignupNetworkError>()
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                switch AuthErrorCode(rawValue: error.code) {
                case .invalidEmail:
                    publisher.send(completion:.failure(.invalidEmail))
                case .emailAlreadyInUse:
                    publisher.send(completion: .failure(.emailAlreadyInUse))
                case .weakPassword:
                    publisher.send(completion:.failure(.weakPassword))
                case .networkError:
                    publisher.send(completion:.failure(.networkError))
                default:
                    publisher.send(completion: .failure(.unknown(error)))
                }
                return
            }
            else {
                print("Registro exitoso.")
                publisher.send()
                publisher.send(completion: .finished)
                
            }
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    func signupCompany(email: String, password: String) -> AnyPublisher<Void, SignupNetworkError> {
        // Lógica con Firebase Auth para registrar el usuario
        let publisher = PassthroughSubject<Void, SignupNetworkError>()
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                switch AuthErrorCode(rawValue: error.code) {
                case .invalidEmail:
                    publisher.send(completion:.failure(.invalidEmail))
                case .emailAlreadyInUse:
                    publisher.send(completion: .failure(.emailAlreadyInUse))
                case .weakPassword:
                    publisher.send(completion:.failure(.weakPassword))
                case .networkError:
                    publisher.send(completion:.failure(.networkError))
                default:
                    publisher.send(completion: .failure(.unknown(error)))
                }
                return
            }
            else {
                print("Registro exitoso de empresa.")
                publisher.send()
                publisher.send(completion: .finished)
                
            }
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never> {
        
        return Future<UserModel?, Never> { promise in
            
            let ref = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: uid)
            
            ref.getData { error, snapshot in
                guard error == nil else {
                    print("Error fetching data: \(error!.localizedDescription)")
                    promise(.success(nil))
                    return
                }
                
                do {
                    if let userModel = try snapshot?.data(as: UserModel.self) {
                        promise(.success(userModel))
                    } else {
                        promise(.success(nil))
                    }
                } catch {
                    print("Error decoding data: \(error.localizedDescription)")
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCompanyInfo(uid: String) -> AnyPublisher<CompanyModel?, Never> {
        
        return Future<CompanyModel?, Never> { promise in
            let ref = FirebaseServiceImpl.shared.getCompanyInDatabaseFrom(uid: uid)
            
            ref.getData { error, snapshot in
                guard error == nil else {
                    print("Error fetching data: \(error!.localizedDescription)")
                    promise(.success(nil))  // Envía `nil` si hay error
                    return
                }
                
                do {
                    if let companyModel = try snapshot?.data(as: CompanyModel.self) {
                        // Asumiendo que deseas crear un PostModel a partir de CompanyModel
                        
                        promise(.success(companyModel))
                    } else {
                        promise(.success(nil))  // Envía `nil` si no se encuentra el modelo
                    }
                } catch {
                    print("Error decoding data: \(error.localizedDescription)")
                    promise(.success(nil))  // Envía `nil` en caso de error
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveUser(model: UserModel) -> AnyPublisher<Bool, Never> {
        
        let publisher = PassthroughSubject<Bool, Never>()
        
        guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            publisher.send(false)
            return publisher.eraseToAnyPublisher()
        }
        
        let userData = structToDictionary(model)
        // Referencia a la sección "Users" en la base de datos
        let ref = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: uid)
        
        ref.setValue(userData) { error, _ in
            if let error = error {
                print("Error al guardar el usuario en la base de datos: \(error.localizedDescription)")
                publisher.send(false)
            } else {
                print("Usuario guardado exitosamente en la base de datos")
                UserDefaults.setUserModel(model)
                publisher.send(true)
            }
        }
        return publisher.eraseToAnyPublisher()
    }
    
#warning("TODO: firebase storage Object profile_pictures/PgUHF5pTC0SytVrqlwOfdhS91Di1.jpg does not exist.")
    func getUrlCompanyImage(imageData: Data) -> AnyPublisher<String?, Never>  {
        let publisher = PassthroughSubject<String?, Never>()
        
        guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            publisher.send(nil)
            return publisher.eraseToAnyPublisher()
        }
        // Referencia a Firebase Storage
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("profile_pictures/\(uid).jpg")
        
        // Subir la imagen a Firebase Storage
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error al subir imagen: \(error.localizedDescription)")
                publisher.send(nil)
            }
            
            // Obtener la URL de la imagen
            imageRef.downloadURL { url, error in
                publisher.send(url?.absoluteString)
            }
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    func saveCompany(model: CompanyModel) -> AnyPublisher<Bool, Never> {
        
        let publisher = PassthroughSubject<Bool, Never>()
        
        guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            publisher.send(false)
            return publisher.eraseToAnyPublisher()
        }
        
        let userData = structToDictionary(model)
        // Referencia a la sección "Users" en la base de datos
        let ref = FirebaseServiceImpl.shared.getCompanyInDatabaseFrom(uid: uid)
        
        ref.setValue(userData) { error, _ in
            if let error = error {
                print("Error al guardar la empresa en la base de datos: \(error.localizedDescription)")
                publisher.send(false)
            } else {
                print("Empresa guardada exitosamente en la base de datos")
                UserDefaults.setCompanyUserModel(model)
                publisher.send(true)
            }
        }
        return publisher.eraseToAnyPublisher()
    }
    
    
    func signOut() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            do {
                try Auth.auth().signOut()
                print("logout success")
                promise(.success(()))
            } catch let signOutError as NSError {
                print("logout failure")
                promise(.failure(signOutError))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAccount() -> AnyPublisher<String?, Never> {
        return Future<String?, Never> { promise in
            guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                promise(.success("Error finding user uid"))
                return
            }
            let ref = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: uid)
            ref.removeValue { error, _ in
                if let error = error {
                    promise(.success(error.localizedDescription))
                    
                } else {
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// Define tu NetworkError
enum LoginNetworkError: Error {
    case invalidCredentials
    case wrongPassword
    case unknown(Error)
    case userDisabled
    
    var localizedDescription: String {
        switch self {
        case .invalidCredentials:
            return "Credenciales de acceso erróneas"
        case .wrongPassword:
            return "Contraseña errónea"
        case .unknown(let error):
            return "Error desconocido: \(error.localizedDescription)."
        case .userDisabled:
            return "Usuario desabilitado"
        }
    }
}

enum SignupNetworkError: Error {
    case invalidEmail
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown(Error)
    case custom(message: String)
    
    var localizedDescription: String {
        switch self {
        case .invalidEmail:
            return "El correo electrónico proporcionado no es válido."
        case .emailAlreadyInUse:
            return "El correo electrónico ya está en uso por otra cuenta."
        case .weakPassword:
            return "La contraseña es demasiado débil."
        case .networkError:
            return "Ocurrió un problema de red. Por favor, intenta de nuevo."
        case .unknown(let error):
            return "Ocurrió desconocido: \(error.localizedDescription)."
        case .custom(let message):
            return message
        }
    }
}

enum SaveCompanyError: Error {
    case noUid
    case noImage
    case dataNotSaved
    
    var localizedDescription: String {
        switch self {
        case .noImage:
            return "La imagen no se ha podido guardar."
        case .dataNotSaved:
            return "Los datos de la empresa no se han podido guardar."
        case .noUid:
            return "Usuario no encontrado."
        }
    }
}
