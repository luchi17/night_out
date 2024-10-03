import UIKit


class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?
    // Método llamado cuando la app ha terminado de lanzarse
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
      //  FirebaseApp.configure()
        return true
    }

    // Opcional: Manejo de notificaciones push
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Enviar el token al servidor para notificaciones push
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Manejar error de registro de notificaciones
    }

    // Otros métodos opcionales del ciclo de vida de la aplicación...
}
