import SwiftUI
import Kingfisher
import Combine

public struct KingFisherImage: View {
    public let url: URL?
    var placeholder: AnyView?
    var configurations: [(Image) -> Image] = []
    public let onSuccessCallback: ((RetrieveImageResult) -> Void)?

    public init(url: URL?, onSuccessCallback: ((RetrieveImageResult) -> Void)? = nil) {
        self.url = url
        self.onSuccessCallback = onSuccessCallback
    }

    public var body: some View {
        KFImage(url)
            .placeholder({ placeholder })
            .fromMemoryCacheOrRefresh()
            .cacheOriginalImage()
            .resizable()
            .waitForCache()
            .onSuccess(onSuccessCallback)
    }
}

public extension KingFisherImage {
    func placeholder(_ image: Image) -> KingFisherImage {
        return placeholder {
            configurations.reduce(image) { previous, configuration in
                configuration(previous)
            }
        }
    }
    
    func resizable(
        capInsets: EdgeInsets = EdgeInsets(),
        resizingMode: Image.ResizingMode = .stretch
    ) -> KingFisherImage {
        configure { $0.resizable(capInsets: capInsets, resizingMode: resizingMode) }
    }
    
    func placeholder<T>(@ViewBuilder _ content: () -> T) -> KingFisherImage where T: View {
        var result = self
        result.placeholder = AnyView(content())
        return result
    }
}

private extension KingFisherImage {
    func configure(_ block: @escaping (Image) -> Image) -> KingFisherImage {
        var result = self
        result.configurations.append(block)
        return result
    }
}

public extension KingFisherImage {
//    func centerCropped<T>(_ placeholderImage: @escaping () -> T) -> some View where T: View {
//        GeometryReader { geo in
//            self
//                .resizable()
//                .placeholder(placeholderImage)
//                .scaledToFill()
//                .frame(width: geo.size.width, height: geo.size.height)
//                .clipped()
//        }
//    }
    
    func centerCropped<T>(width: CGFloat, height: CGFloat, placeholder: @escaping () -> T) -> some View where T: View {
        self
            .resizable()
            .placeholder(placeholder)
            .scaledToFill()
            .frame(maxWidth: width, maxHeight: height)
            .clipped()
    }
}

extension KingFisherImage {
    private static func fetchImage(url: URL, scaleFactor: CGFloat? = nil, completion: ((Result<UIImage?, Never>) -> Void)?) {
        DispatchQueue.main.async {
            KingfisherManager.shared.retrieveImage(
                with: KF.ImageResource(downloadURL: url),
                options: [
    //                .scaleFactor(scaleFactor ?? 1),
                    .fromMemoryCacheOrRefresh,
                    .cacheMemoryOnly,
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(0.2)),
                    .backgroundDecode
                ],
                completionHandler: { result in
                    switch result {
                    case .success(let image):
                        completion?(.success(image.image))
                    case .failure:
                        completion?(.success(nil))
                    }
                }
            )
        }
       
    }
    
    public static func fetchImagePublisher(url: URL, scaleFactor: CGFloat? = nil) -> AnyPublisher<UIImage?, Never> {
        return Future<UIImage?, Never> { promise in
            
            KingFisherImage.fetchImage(url: url, scaleFactor: scaleFactor) { result in
                switch result {
                case .success(let image):
                    promise(.success(image))
                case .failure(_):
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
