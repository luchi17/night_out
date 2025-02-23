import AVKit
import PhotosUI
import SwiftUI

struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "movie.mp4")

            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }

            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}

struct VideoPickerView<Content: View>: View {
    @State private var selectedItem: PhotosPickerItem?
    
    @State private var videoData: PhotosPickerItem?
//    @Binding var videoData: Data?
    @Binding var selectedVideoURL: URL?
    
    let content: () -> Content
    
    var body: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItem,
                matching: .videos,
                photoLibrary: .shared()) {
                    content()
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let newItem = newItem {
                            if let movie = try? await newItem.loadTransferable(type: Movie.self) {
                                selectedVideoURL = movie.url
                                if let data = try? Data(contentsOf: movie.url) {
//                                    videoData = data
                                    print("data")
                                    print(data)
                                }
                            }
                        }
                    }
                }
        }
    }
}


//struct ContentView: View {
//    enum LoadState {
//        case unknown, loading, loaded(Movie), failed
//    }
//
//    @State private var selectedItem: PhotosPickerItem?
//    @State private var loadState = LoadState.unknown
//
//    var body: some View {
//        VStack {
//            PhotosPicker("Select movie", selection: $selectedItem, matching: .videos)
//
//            switch loadState {
//            case .unknown:
//                EmptyView()
//            case .loading:
//                ProgressView()
//            case .loaded(let movie):
//                VideoPlayer(player: AVPlayer(url: movie.url))
//                    .scaledToFit()
//                    .frame(width: 300, height: 300)
//            case .failed:
//                Text("Import failed")
//            }
//        }
//        .onChange(of: selectedItem) { _ in
//            Task {
//                do {
//                    loadState = .loading
//
//                    if let movie = try await selectedItem?.loadTransferable(type: Movie.self) {
//                        loadState = .loaded(movie)
//                    } else {
//                        loadState = .failed
//                    }
//                } catch {
//                    loadState = .failed
//                }
//            }
//        }
//    }
//}
