import SwiftUI

struct ImagesGrid: View {
    
    @Binding var images: [IdentifiableImage]
    @Binding var selectedImage: IdentifiableImage?
    
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(images, id: \.id) { imageName in
                    Image(uiImage: imageName.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .onTapGesture {
                            selectedImage = imageName
                        }
                }
            }
            .padding()
        }
    }
}


// Vista de imagen a pantalla completa con zoom
struct FullScreenImageView: View {
    let imageName: IdentifiableImage
    let onClose: () -> Void
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.blackColor.ignoresSafeArea()
            
            Image(uiImage: imageName.image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        scale = scale > 1 ? 1 : 2
                        lastScale = scale
                    }
                }
                .padding(.horizontal, 20)
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image("borrar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}
