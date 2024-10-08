import Combine
import Foundation

public extension Publisher where Failure == Never {
    /// Safe request handler. It emits true and false on the loadingSubject and every error is filtered.
    ///
    /// - Parameter request: Request.
    /// - Parameter onLoading: Emit true when the request starts and false when the request has completed/failed or once an output is received .
    /// - Parameter onError: Errors behaviour will be handled here.
    ///
    func performRequest<T, E: Error>(
        request: @escaping (Output) -> AnyPublisher<T, E>,
        loadingClosure: InputClosure<Bool>? = nil,
        onError: InputClosure<E?>? = nil
    ) -> AnyPublisher<T, Never> {
        self.flatMapLatest { value -> AnyPublisher<T, Never> in
            return request(value)
                .handleEvents(
                    receiveOutput: { _ in
                        onError?(nil)
                        loadingClosure?(false)
                    },
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            loadingClosure?(false)
                        case .failure(let error):
                            onError?(error)
                            loadingClosure?(false)
                        }
                    },
                    receiveCancel: {
                        // If we cancel loading closure here. We get autocancel pull to refresh animations in the places that we were still listening changes.
                    },
                    receiveRequest: { _ in
                        loadingClosure?(true)
                    }
                )
                .ignoreFailure()
        }
        .eraseToAnyPublisher()
    }
}

private extension Publisher {
    func enumerated() -> AnyPublisher<(Int, Self.Output), Self.Failure> {
        scan(Optional<(Int, Self.Output)>.none) { acc, next in
            guard let acc = acc else { return (0, next) }
            return (acc.0 + 1, next)
        }
        .map { $0! }
        .eraseToAnyPublisher()
    }
}


public extension Publisher {
    func transformMap<T>(_ transform: @escaping (Output) -> Result<T, Failure>) -> AnyPublisher<T, Failure> {
        self.flatMap { value -> AnyPublisher<T, Failure> in
            switch transform(value) {
            case .success(let success):
                return Just(success).setFailureType(to: Failure.self).eraseToAnyPublisher()
            case .failure(let error):
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }

    static func just(_ output: Output) -> AnyPublisher<Output, Failure> {
        return Just(output).setFailureType(to: Failure.self).eraseToAnyPublisher()
    }

    static func failure(_ error: Failure) -> AnyPublisher<Output, Failure> {
        return Fail(error: error).eraseToAnyPublisher()
    }

    static func empty(completeImmediately: Bool = true) -> AnyPublisher<Output, Failure> {
        return Empty<Output, Failure>(completeImmediately: completeImmediately).eraseToAnyPublisher()
    }

    func nullable() -> AnyPublisher<Output?, Failure> {
        return self
            .map({ $0 as Output? })
            .eraseToAnyPublisher()
    }

    func withUnretained<T: AnyObject>(_ object: T) -> Publishers.CompactMap<Self, (T, Self.Output)> {
        compactMap { [weak object] output in
            guard let object = object else {
                return nil
            }
            return (object, output)
        }
    }
}

public extension Publisher {
    #warning("Are endpoints being autorefresh when the app is in background? Is it a problem?")
//    func autoRefresh(interval: TimeInterval = 30, enabled: AnyPublisher<Bool, Failure>, visible: AnyPublisher<Bool, Failure>) -> AnyPublisher<Output, Failure> {
//        return self
//            .flatMapLatest({ data -> AnyPublisher<Output, Failure> in
//                let timer = Timer.publish(every: interval, on: .main, in: .default)
//                    .autoconnect()
//                    .setFailureType(to: Failure.self)
//                    .mapToVoid()
//
//                return timer
//                    .withLatestFrom(enabled, visible) { (enabled: $1.0, visible: $1.1) }
//                    .filter({ $0.enabled && $0.visible })
//                    .map({ _ in
//                        data
//                    })
//                    .prepend(data)
//                    .eraseToAnyPublisher()
//        })
//        .eraseToAnyPublisher()
//    }

    func filterWith<Other>(_ gate: Other) -> AnyPublisher<Output, Failure> where Other: Publisher, Other.Output == Bool, Other.Failure == Failure {
        Publishers.CombineLatest(self, gate)
            .filter { $0.1 }
            .map { $0.0 }
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    func flatMapLatest<T: Publisher>(_ transform: @escaping (Output) -> T) -> AnyPublisher<T.Output, Failure> where T.Failure == Failure {
        self.map(transform)
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    func ignoreFailure() -> AnyPublisher<Output, Never> {
        self.catch { _ in Empty() }
            .eraseToAnyPublisher()
    }
}
