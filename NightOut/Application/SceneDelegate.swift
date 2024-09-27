//
//  SceneDelegate.swift
//  NightOut
//
//  Created by Apple on 27/9/24.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // Método llamado cuando una nueva escena se conecta
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Si estás usando SwiftUI, configurar la vista principal aquí.
        
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        
        let window = Window(windowScene: windowScene)
        window.makeKeyAndVisible()
        let contentView = ContentView()
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            
            // Crear la vista principal (Root View) usando SwiftUI
            let contentView = ContentView()

            // Establecer el controlador raíz como la vista SwiftUI
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    // Otros métodos de ciclo de vida de la escena...
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Guardar el estado cuando la escena entre en el fondo
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Restaurar el estado cuando la escena vuelva al primer plano
    }

}
