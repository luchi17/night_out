import SwiftUI
import PhotosUI

struct ImagePickerView<Content: View>: View {
    @State private var selectedItem: PhotosPickerItem?
    
    @Binding var imageData: Data?
    @Binding var selectedImage: UIImage?
    
    let content: () -> Content
    
    var body: some View {
        VStack {
            PhotosPicker(
                "Holi",
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            )
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let newItem = newItem {
                            if let data = try? await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                imageData = data
                                selectedImage = uiImage
                            }
                        }
                    }
                }
        }
    }
}

