import SwiftUI
import FirebaseDatabase

struct AdvertisementView: View {
    @Binding var imageList: [String]
    @Binding var currentIndex: Int
    
    let defaultImageName = "logo_amarillo"
    
    var openUrl: InputClosure<String>
    
    var body: some View {
        VStack(spacing: 0) {
            
            if let imageUrl = imageList.isEmpty ? nil : URL(string: imageList[currentIndex]) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .transition(.opacity)
                            .frame(maxWidth: .infinity, maxHeight: 110)
                            .clipped()
                            .onTapGesture {
                                openUrl(imageList[currentIndex])
                            }
                    case .failure:
                        Image(defaultImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 90)
                    @unknown default:
                        Image(defaultImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 90)
                        
                    }
                }
            } else {
                Image(defaultImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 90)
            }
        }
    }
}
