import SwiftUI
import FirebaseDatabase

struct AdvertisementView: View {
    @Binding var imageList: [String]
    @Binding var currentIndex: Int
    
    let defaultImageName = "logo_amarillo"
    
    var body: some View {
        VStack {
            
            if let imageUrl = imageList.isEmpty ? nil : URL(string: imageList[currentIndex]) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .transition(.opacity)
                            .frame(maxWidth: .infinity, maxHeight: 50)
                    case .failure:
                        Image(defaultImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 50)
                    @unknown default:
                        Image(defaultImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 50)
                        
                    }
                }
            } else {
                Image(defaultImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 50)
            }
        }
    }
}
