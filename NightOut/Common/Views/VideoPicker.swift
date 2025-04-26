import SwiftUI
import PhotosUI
import AVKit

struct Movie: Transferable {
  let url: URL

  static var transferRepresentation: some TransferRepresentation {
      
    FileRepresentation(contentType: .movie) { movie in
      SentTransferredFile(movie.url)
        
    } importing: { receivedData in
    
      let copy = URL.documentsDirectory.appending(path: "movie.mp4")

      if FileManager.default.fileExists(atPath: copy.path) {
        try FileManager.default.removeItem(at: copy)
      }

      try FileManager.default.copyItem(at: receivedData.file, to: copy)
      return .init(url: copy)
    }
  }
}
