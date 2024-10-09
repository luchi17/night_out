import Combine
import Foundation
import FirebaseAuth
import FirebaseDatabase

protocol AccountDatasource {
    func login(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError>
    func signup(email: String, password: String) -> AnyPublisher<Void, SignupNetworkError>
    func saveUser(model: UserModel) -> AnyPublisher<Bool, Never>
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
                // Signup exitoso
                print("Signup exitoso.")
                // Obtener el UID del usuario creado
//                if let uid = authResult?.user.uid {
//                    self.saveUser()
//                    publisher.send()
//                    publisher.send(completion: .finished)
//                } else {
//                    publisher.send(completion: .failure(.custom(message: "Identificador del usuario no encontrado.")))
//                }
                publisher.send()
                publisher.send(completion: .finished)
                
            }
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    func saveUser(model: UserModel) -> AnyPublisher<Bool, Never> {
        // Obtener el UID del usuario creado
        
        let publisher = PassthroughSubject<Bool, Never>()
        
        guard let uid = FirebaseServiceImpl.shared.currentUser?.uid else {
            publisher.send(false)
            return publisher.eraseToAnyPublisher()
        }
        
        let userData = structToDictionary(model)
        // Referencia a la sección "Users" en la base de datos
        let ref = Database.database().reference().child("Users").child(uid)
        
        ref.setValue(userData) { error, _ in
            if let error = error {
                print("Error al guardar el usuario en la base de datos: \(error.localizedDescription)")
                publisher.send(false)
            } else {
                print("Usuario guardado exitosamente en la base de datos")
                publisher.send(true)
            }
        }
        return publisher.eraseToAnyPublisher()
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
            return "Ocurrió desconocido: \(error.localizedDescription)."
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
