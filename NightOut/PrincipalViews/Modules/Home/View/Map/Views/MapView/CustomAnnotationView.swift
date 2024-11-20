import SwiftUI
import UIKit
import MapKit

#warning("Is this an asset?")
struct CustomAnnotationView: View {
    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(.gray)
                .stroke(Color.pink, lineWidth: 3)
            // Imagen del vaso en el centro
            Image(systemName: "wineglass.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.blue)
                .frame(width: 25, height: 25)
        }
        .frame(width: 35, height: 35)
    }
}

struct UserAnnotationView: View {
    var body: some View {
        ZStack(alignment: .center) {
//            Circle()
//                .fill(.blue)
            // Imagen del vaso en el centro
            Image(systemName: "mappin.circle")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: 28, height: 28) // Ajusta el tamaño de la imagen
        }
        .frame(width: 30, height: 30)
    }
}


class CustomAnnotationViewWrapper: MKAnnotationView {
    private var hostingController: UIHostingController<CustomAnnotationView>?
    
    func setupContent() {
        let customView = CustomAnnotationView()
        
        if hostingController == nil {
            hostingController = UIHostingController(rootView: customView)
            hostingController?.view.backgroundColor = .clear
            addSubview(hostingController!.view)
        } else {
            hostingController?.rootView = customView
        }
        
        // Ajustar el tamaño de la vista de anotación
        hostingController?.view.frame = CGRect(x: -20, y: -30, width: 40, height: 60)
        
        // Ajustar el desplazamiento para que la punta de la gota esté en el punto de coordenadas
        centerOffset = CGPoint(x: 0, y: -10) // Desplaza la anotación hacia arriba para que la punta esté en el centro de la ubicación
    }
}
