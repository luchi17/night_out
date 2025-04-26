import SwiftUI

func shareProfile(profileId: String, viewController: UIViewController) {
    // Crear el enlace profundo con el ID de perfil como parámetro
    let appLink = "nightout://profile/\(profileId)"  // Enlace profundo personalizado de la app
    
    // Crear el texto para compartir
    let shareText = "¡Echa un vistazo a este perfil en NightOut! \(appLink)"
    
    // Crear el UIActivityViewController para compartir
    let activityController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
    
    // Excluir algunas actividades no necesarias (opcional)
    activityController.excludedActivityTypes = [.addToReadingList, .postToFacebook]

    // Iniciar el ActivityViewController
    viewController.present(activityController, animated: true, completion: nil)
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No necesitamos actualizar nada en este caso
    }
}
