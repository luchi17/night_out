//
//  AppDelegate.swift
//  NightOut
//
//  Created by Apple on 27/9/24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Método llamado cuando la app ha terminado de lanzarse
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configuración inicial de Firebase, analíticas u otros servicios
      //  FirebaseApp.configure()

        // Configuración inicial, si es necesario
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
