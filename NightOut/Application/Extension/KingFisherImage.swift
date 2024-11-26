import SwiftUI
import Kingfisher

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
            .waitForCache()
            .resizable()
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

import Combine

extension KingFisherImage {
    enum WebImageError: Error {
        case failure
    }

    public static func fetchImage(url: URL, scaleFactor: CGFloat? = nil, completion: ((Result<UIImage?, Error>) -> Void)?) {
        KingfisherManager.shared.retrieveImage(
            with: KF.ImageResource(downloadURL: url),
            options: scaleFactor.map { [.scaleFactor($0)] },
            completionHandler: { result in
                switch result {
                case .success(let image):
                    completion?(.success(image.image))
                case .failure:
                    completion?(.failure(WebImageError.failure))
                }
            }
        )
    }
}
