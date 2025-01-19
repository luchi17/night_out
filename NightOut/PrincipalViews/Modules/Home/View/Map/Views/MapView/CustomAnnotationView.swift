import SwiftUI
import UIKit
import MapKit

struct CustomAnnotationView: View {
    
    @State private var isSelected = false
    
    var club: LocationModel
    @Binding var selection: LocationModel?
    
    var body: some View {
//        ZStack(alignment: .center) {
//            Circle()
//                .fill(.gray)
//                .stroke(Color.pink, lineWidth: 3)
//                .frame(width: isSelected ? 40 : 28, height: isSelected ? 40 : 28)
//            Image(systemName: "wineglass.fill")
//                .resizable()
//                .scaledToFit()
//                .foregroundStyle(.blue)
//                .frame(width: isSelected ? 18 : 10)
//        }
        Image("map_marker")
            .resizable()
            .scaledToFit()
        .frame(width: isSelected ? 40 : 28, height: isSelected ? 40 : 28)
        .onTapGesture {
          selection = club
            withAnimation(.bouncy) {
                isSelected = true
            }
        }
        .onChange(of: selection, { oldValue, newValue in
            withAnimation(.bouncy) {
                isSelected = newValue == club
            }
        })
    }
}

struct UserAnnotationView: View {
    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(.blue)
            Image(systemName: "mappin.circle")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: 28, height: 28) // Ajusta el tamaño de la imagen
        }
    }
}
