import SwiftUI
import UIKit
import MapKit

struct CustomAnnotationView: View {
    
    @State private var isSelected = false
    
    var club: LocationModel
    @Binding var selection: LocationModel?
    
    var body: some View {
        Image("map_marker")
            .resizable()
            .scaledToFit()
            .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
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
                .frame(width: 28, height: 28)
        }
    }
}

struct UserLocationButtonView: View {
    let onTap: VoidClosure
    
    var body: some View {
        
        Button(action: {
            onTap()
        }) {
            Image(systemName: "location.fill")
                .font(.title)
                .foregroundStyle(.blue)
                .frame(width: 30, height: 30)
        }
    }
}
