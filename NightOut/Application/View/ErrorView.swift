import SwiftUI

struct CustomBackButton: View {
    @Environment(\.dismiss) var dismiss // Para retroceder en la pila de navegación
    
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "arrow.backward")
                    .foregroundStyle(.white)
            }
        }
    }
}


public extension View {
    @ViewBuilder
    func showCustomBackButtonNavBar() -> some View {
        self
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CustomBackButton()
                }
            }
    }
    
    func showCustomNavBar<T: View>(
        title: String,
        goBack: @escaping VoidClosure,
        @ViewBuilder image: @escaping () -> T = { EmptyView() } ) -> some View {
        self
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        goBack()
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.white)
                        image()
                    }
                }
            }
    }
}


public extension View {
    @ViewBuilder
    func applyErrorView(_ error: ErrorState?, onReload: @escaping () -> Void, closeButton: VoidClosure?) -> some View {
        if let error = error {
            ErrorView(
                state: error,
                retryHandler: onReload,
                showCloseButton: closeButton
            )
        } else {
            self
        }
    }
}

public class ErrorState: ObservableObject {
    @Published public var isRetrying: Bool
    @Published public var error: ErrorPresentationType

    public init?(errorOptional: ErrorPresentationType?) {
        guard let error = errorOptional else {
            return nil
        }
        self.isRetrying = false
        self.error = error
    }

    public init(error: ErrorPresentationType) {
        self.isRetrying = false
        self.error = error
    }
}

public enum ErrorPresentationType: Error {
    case generic
    case offline
    case custom(ErrorViewDescriptor)
}

extension ErrorPresentationType {
    var title: String {
        switch self {
        case .offline:
            return "Connection Error"
        case .generic:
            return "App Error"
        case .custom(let descriptor):
            return descriptor.title
        }
    }

    var description: String {
        switch self {
        case .offline:
            return "An error occurred trying to process the request, please check your Internet connection and try again."
        case .generic:
            return "An unexpected error has occurred, please tap the 'retry' button. If the problem persists, please try closing your app and and starting it again."
        case .custom(let descriptor):
            return descriptor.description
        }
    }

    var buttonTitle: String {
        switch self {
        case .offline, .generic:
            return "Retry"
        case .custom(let descriptor):
            return descriptor.buttonTitle
        }
    }

    var buttonIcon: String? {
        switch self {
        case .offline, .generic:
            return "refresh"
        case .custom:
            return nil
        }
    }

    var iconName: String {
        switch self {
        case .offline, .generic:
            return "errorWarning"
        case .custom(let descriptor):
            return descriptor.iconName
        }
    }

    public static func makeCustom(title: String, description: String) -> ErrorPresentationType {
        return .custom(
            ErrorViewDescriptor(
                iconName: "errorWarning",
                title: title,
                description: description,
                buttonTitle: "Retry"
            )
        )
    }
}

public struct ErrorViewDescriptor {
    public let iconName: String
    public let title: String
    public let description: String
    public let buttonTitle: String
}

public struct ErrorView: View {
    @ObservedObject private var state: ErrorState
    private let retryHandler: VoidClosure
    private let showCloseButton: VoidClosure?
    
    public init(
        state: ErrorState,
        retryHandler: @escaping VoidClosure,
        showCloseButton: VoidClosure?
    ) {
        self.state = state
        self.retryHandler = retryHandler
        self.showCloseButton = showCloseButton
    }

    public var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(state.error.iconName)
                .renderingMode(.template)
                .aspectRatio(contentMode: .fill)
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            Text(state.error.title)
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300)
            Text(state.error.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
                .frame(minHeight: 40, idealHeight: 80, maxHeight: 80)
            Button(
                action: {
                    state.isRetrying = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        retryHandler()
                    })
                },
                label: {
                    ZStack(alignment: .center) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .opacity(state.isRetrying ? 1 : 0)
                        HStack(spacing: 6) {
                            if let buttonIcon = state.error.buttonIcon {
                                Image(buttonIcon)
                                    .foregroundColor(.white)
                                Text(state.error.buttonTitle)
                                    .foregroundColor(.white)
                                    .fixedSize()
                            } else {
                                Text(state.error.buttonTitle)
                                    .foregroundColor(.white)
                                    .fixedSize()
                            }
                        }
                        .opacity(state.isRetrying ? 0 : 1)
                    }
                }
            )
            Spacer()
        }
        .if(showCloseButton != nil, transform: { view in
            view
                .overlay(alignment: .topTrailing, content: {
                Button(action: {
                    showCloseButton?()
                }) {
                    Image(systemName: "xmark") // Icono de cerrar estándar
                        .font(.system(size: 20, weight: .bold))
                }
            })
        })
        .padding(32)
        .background(.white)
    }
}

public extension View {
    @ViewBuilder
    func applyStates(
        error: (state: ErrorState?, onReload: () -> Void)?,
        isIdle: Bool,
        showCloseButton: VoidClosure? = nil
    ) -> some View {
        VStack(spacing: 0) {
            if error?.state == nil, isIdle {
                ZStack { //(alignment: .top)
                    self
                    DefaultIdleView()
                }
            } else {
                if let error = error, let errorState = error.state {
                    ErrorView(
                        state: errorState,
                        retryHandler: error.onReload,
                        showCloseButton: showCloseButton
                    )
                } else {
                    self
                }
            }
        }
    }
}

public struct DefaultIdleView: View {
    public init() { }

    public var body: some View {
        VStack(spacing: 0) {
            ProgressView()
                .tint(Color.white)
                .padding(.top, 70)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
