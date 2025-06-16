
import SwiftUI
import Combine
import FirebaseAuth
import GoogleSignIn

final class LoginViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    init() { }
    
}

protocol LoginPresenter {
    var viewModel: LoginViewModel { get }
    func transform(input: LoginPresenterImpl.ViewInputs)
}

final class LoginPresenterImpl: LoginPresenter {
    
    struct UseCases {
        let loginUseCase: LoginUseCase
        let companyLocationsUseCase: CompanyLocationsUseCase
        let userDataUseCase: UserDataUseCase
        let saveUserUseCase: SaveUserUseCase
        let companyDataUseCase: CompanyDataUseCase
    }
    
    struct Actions {
        var goToTabView: VoidClosure
        var goToRegisterUser: VoidClosure
        var goToRegisterCompany: VoidClosure
        var goToForgotPassword: VoidClosure
    }
    
    struct ViewInputs {
        let login: AnyPublisher<Void, Never>
        let signupUser: AnyPublisher<Void, Never>
        let signupCompany: AnyPublisher<Void, Never>
        let signupWithGoogle: AnyPublisher<Void, Never>
        let signupWithApple: AnyPublisher<Void, Never>
        let openForgotPassword: AnyPublisher<Void, Never>
    }
    
    var viewModel: LoginViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = LoginViewModel()
    }
    
    func transform(input: LoginPresenterImpl.ViewInputs) {
        
        loginListener(input: input)
        signupListener(input: input)
        signupCompanyListener(input: input)
        loginGoogleListener(input: input)
        loginAppleListener(input: input)
        
        input
            .openForgotPassword
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.goToForgotPassword()
            }
            .store(in: &cancellables)
    }
    
    func loginListener(input: LoginPresenterImpl.ViewInputs) {
        input
            .login
            .filter({ [weak self] _ in
                if (self?.viewModel.password.isEmpty ?? true) || (self?.viewModel.email.isEmpty ?? true) {
                    self?.viewModel.toast = .custom(.init(title: "Error", description: "Por favor, ingresa tu email y contraseña.", image: nil))
                    self?.viewModel.loading = false
                    return false
                }
                
                return true
            })
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.useCases.loginUseCase.execute(
                    email: presenter.viewModel.email,
                    password: presenter.viewModel.password
                )
                .eraseToAnyPublisher()
            }, loadingClosure: { _ in },
            onError: { [weak self] error in
                guard let self = self else { return }
                
                if error != nil {
                    self.viewModel.toast = .custom(.init(title: "Error", description: error?.localizedDescription, image: nil))
                    self.viewModel.loading = false
                }
               
            })
            .withUnretained(self)
            .flatMap({ presenter, _ -> AnyPublisher<Bool, Never> in
                presenter.useCases.companyLocationsUseCase.fetchCompanyLocations()
                    .map({ companies in
                        let imCompany = companies?.users.map({ $0.value.email }).contains(presenter.viewModel.email.lowercased()) ?? false
                        return imCompany
                    })
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .flatMap({ presenter, imCompany -> AnyPublisher<Void, Never> in
                presenter.saveInfo(imCompany: imCompany)
            })
            .withUnretained(self)
            .sink(receiveValue: { [weak self] _ in
                self?.viewModel.loading = false
                self?.viewModel.email = ""
                self?.viewModel.password = ""
                self?.actions.goToTabView()
            })
            .store(in: &cancellables)
    }
    
    func signupListener(input: LoginPresenterImpl.ViewInputs) {
        input
            .signupUser
            .withUnretained(self)
            .sink(receiveValue: { presenter, _ in
                self.actions.goToRegisterUser()
            })
            .store(in: &cancellables)
    }
    
    func signupCompanyListener(input: LoginPresenterImpl.ViewInputs) {
        input
            .signupCompany
            .withUnretained(self)
            .sink(receiveValue: { presenter, _ in
                self.actions.goToRegisterCompany()
            })
            .store(in: &cancellables)
    }
    
    func loginGoogleListener(input: LoginPresenterImpl.ViewInputs) {
        input
            .signupWithGoogle
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.useCases.loginUseCase.executeGoogle()
            }, loadingClosure: { _ in },
               onError: { [weak self] error in
                guard let self = self else { return }
                
                if error != nil {
                    self.viewModel.toast = .custom(.init(title: "Error", description: "No se pudo completar el inicio de sesión con Google. Inténtalo de nuevo.", image: nil))
                    self.viewModel.loading = false
                }
            })
            .withUnretained(self)
            .flatMap({ presenter, googleUser -> AnyPublisher<(GIDGoogleUser, UserModel?), Never> in
                
                let email = googleUser.profile?.email ?? ""
                
                return presenter.useCases.userDataUseCase.findUserByEmail(email)
                    .map({ (googleUser, $0) })
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .flatMap({ presenter, data -> AnyPublisher<UserModel?, Never> in
                let googleUser = data.0
                let userModel = data.1
                
                if let userModel = userModel {
                    return presenter.saveInfo(imCompany: false) //Google accounts not for companyusers
                        .map({ _ in userModel })
                        .eraseToAnyPublisher()
                } else {
                    return presenter.useCases.saveUserUseCase.execute(model: presenter.getGoogleUserInfo(googleUser: googleUser))
                        .map({ _ in userModel })
                        .eraseToAnyPublisher()
                }
            })
        
            .withUnretained(self)
            .flatMap({ presenter, userModel in
                if userModel != nil { //User already existed
                    return Just(true).eraseToAnyPublisher()
                } else {
                    return presenter.useCases.saveUserUseCase.executeTerms()
                }
                
            })
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.companyLocationsUseCase.fetchCompanyLocations()
            })
            .withUnretained(self)
            .sink(receiveValue: { [weak self] _ in
                self?.viewModel.loading = false
                self?.actions.goToTabView()
                self?.viewModel.email = ""
                self?.viewModel.password = ""
            })
            .store(in: &cancellables)
        
    }
    
    func loginAppleListener(input: LoginPresenterImpl.ViewInputs) {
        //        input
        //            .signupWithApple
        //            .withUnretained(self)
        
    }
    
}

private extension LoginPresenterImpl {
    
    func getGoogleUserInfo(googleUser: GIDGoogleUser) -> UserModel {
        // Extraer información del usuario de Google
        let fullName = googleUser.profile?.name ?? "Sin Nombre"
        let userName = googleUser.profile?.email.components(separatedBy: "@").first ?? "Sin Usuario"
        let photoURL = googleUser.profile?.imageURL(withDimension: 200)?.absoluteString ?? ""
        
        let userModel = UserModel(
            uid: FirebaseServiceImpl.shared.getCurrentUserUid()!,
            fullname: fullName,
            username: userName,
            email: googleUser.profile?.email ?? "",
            image: photoURL,
            fcm_token: "Sin Token"
        )
        
        return userModel
    }
    
    func getUserInfo() -> AnyPublisher<UserModel?, Never> {
        guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return Just(nil).eraseToAnyPublisher()
        }
        return self.useCases.userDataUseCase.getUserInfo(uid: uid)
            .eraseToAnyPublisher()
    }
    
    func getCompanyInfo() -> AnyPublisher<CompanyModel?, Never> {
        guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return Just(nil).eraseToAnyPublisher()
        }
        return self.useCases.companyDataUseCase.getCompanyInfo(uid: uid)
            .eraseToAnyPublisher()
    }
    
    func saveInfo(imCompany: Bool) -> AnyPublisher<Void, Never> {
        if imCompany {
            getCompanyInfo()
                .filter { [weak self] companyModel in
                    if companyModel == nil {
                        self?.viewModel.loading = false
                        self?.viewModel.toast = .custom(.init(title: "Error", description: "Usuario no válido.", image: nil))
                        return false
                    }
                    return true
                }
                .handleEvents(receiveOutput: { model in
                    UserDefaults.setCompanyUserModel(model!)
                })
                .map({ _ in })
                .eraseToAnyPublisher()
        } else {
            getUserInfo()
                .filter { [weak self] userModel in
                    if userModel == nil {
                        self?.viewModel.loading = false
                        self?.viewModel.toast = .custom(.init(title: "Error", description: "Usuario no válido.", image: nil))
                        return false
                    }
                    return true
                }
                .handleEvents(receiveOutput: { model in
                    UserDefaults.setUserModel(model!)
                })
                .map({ _ in })
                .eraseToAnyPublisher()
        }
    }
}

//private fun loginAsAdmin(email: String, password: String) {
//    // Validar si son las credenciales de administrador
//    if (email == "admin@nightout.com" && password == "Admin_NightOut_04052001_28022001") {
//        // Autenticar con Firebase Authentication
//        FirebaseAuth.getInstance().signInWithEmailAndPassword(email, password)
//            .addOnCompleteListener { task ->
//                if (task.isSuccessful) {
//                    // Obtener el usuario autenticado
//                    val currentUser = FirebaseAuth.getInstance().currentUser
//                    if (currentUser != null) {
//                        val adminUid = currentUser.uid
//
//                        // Verificar si este UID está registrado en el nodo Admins
//                        val adminsRef = FirebaseDatabase.getInstance().getReference("Admins")
//                        adminsRef.child(adminUid).addListenerForSingleValueEvent(object : ValueEventListener {
//                            override fun onDataChange(snapshot: DataSnapshot) {
//                                if (snapshot.exists()) {
//                                    // Es un administrador válido, redirigir a AdminActivity
//                                    val adminIntent = Intent(this@SignInActivity, AdminActivity::class.java)
//                                    startActivity(adminIntent)
//                                    finish() // Opcional: cerrar esta actividad
//                                } else {
//                                    Toast.makeText(this@SignInActivity, "El UID no está autorizado como administrador", Toast.LENGTH_LONG).show()
//                                    FirebaseAuth.getInstance().signOut() // Cierra sesión si no está autorizado
//                                }
//                            }
//
//                            override fun onCancelled(error: DatabaseError) {
//                                Toast.makeText(this@SignInActivity, "Error al verificar administrador: ${error.message}", Toast.LENGTH_LONG).show()
//                            }
//                        })
//                    } else {
//                        Toast.makeText(this, "Error al obtener usuario actual", Toast.LENGTH_LONG).show()
//                    }
//                } else {
//                    Toast.makeText(this, "Error de autenticación: ${task.exception?.message}", Toast.LENGTH_LONG).show()
//                }
//            }
//    } else {
//        // Credenciales incorrectas
//
//    }
//}
