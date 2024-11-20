import SwiftUI
import UIKit
import MapKit

#warning("Is this an asset?")
struct CustomAnnotationView: View {
    
    @State private var isSelected = false
    
    var club: LocationModel
    @Binding var selection: LocationModel?
    
    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(.gray)
                .stroke(Color.pink, lineWidth: 3)
            Image(systemName: "wineglass.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.blue)
                .frame(width: isSelected ? 18 : 12)
        }
        .frame(width: isSelected ? 40 : 28, height: isSelected ? 40 : 28)
        .onTapGesture { // If it is the selected `annotation` from the `ForEach`, define the selection.
          selection = club
          withAnimation(.bouncy) { isSelected = true }
        }
        .onChange(of: selection, { oldValue, newValue in
            // If the previous selected `annotation` from the `ForEach` is unselected, perform the changes.
            guard isSelected, newValue == nil else { return } // Avoid having actions on unselected `annotations`.
            withAnimation(.bouncy) { isSelected = false }
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
