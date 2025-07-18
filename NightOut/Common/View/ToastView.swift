import SwiftUI

public enum ToastPadding {
    case small
    case large
    case none
    
    var value: CGFloat {
        switch self {
        case .small:
            return 10
        case .large:
            return 55
        case .none:
            return 0
        }
    }
}

struct ToastView: View {
    var type: ToastType
    var onDismiss: VoidClosure?
    var showCloseButton: Bool = false
    
    var extraPadding: ToastPadding = .none
    var showTransition: Bool = true
    
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            if isVisible {
                HStack(spacing: 20) {
                    type.image
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(type.imageColor)
                        .frame(width: 24, height: 24)
                        .padding(.leading, 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        if !type.title.isEmpty {
                            Text(type.title)
                                .font(.headline)
                                .foregroundColor(Color.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                       
                        if let description = type.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(Color.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    if showCloseButton, let onDismiss = onDismiss {
                        Button(action: {
                            withAnimation {
                                isVisible = false
                                onDismiss()
                            }
                        }) {
                            Image(systemName: "xmark") // Icono de cerrar estándar
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 20)
                    }
                }
                .padding(.top, 15 + extraPadding.value) //extraPadding
                .padding(.bottom, 15)
                .background(type.backgroundColor) // corner radius: , in: RoundedRectangle(cornerRadius: 10)
                .if(showTransition, transform: { view in
                    view
                        .transition(.move(edge: .top))  // Transición desde arriba
                })
                .zIndex(1)  // Asegura que el toast esté sobre otras vistas
            }
            Spacer()
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isVisible = false
                onDismiss?()
            }
        }
    }
}


public class ToastDescriptor {
    public let title: String
    public let description: String?
    public let image: (image: Image, color: Color)?
    public let backgroundColor: Color?
    
    init(title: String, description: String?, image: (image: Image, color: Color)?, backgroundColor: Color? = nil) {
        self.title = title
        self.description = description
        self.image = image
        self.backgroundColor = backgroundColor
    }
}

public enum ToastType {
    case success(ToastDescriptor)
    case defaultError
    case custom(ToastDescriptor)
    
    var backgroundColor: Color {
        switch self {
        case .defaultError:
            return Color.red.opacity(0.9)
        case .custom(let descriptor):
            return descriptor.backgroundColor ?? Color.red
        case .success(_):
            return Color.green
        }
    }
    
    var imageColor: Color {
        switch self {
        case .defaultError:
            return Color.red
        case .custom(let descriptor):
            return descriptor.image?.color ?? Color.white
        case .success(let descriptor):
            return descriptor.image?.color ?? Color.white
        }
    }
    
    var title: String {
        switch self {
        case .defaultError:
            return "Error"
        case .custom(let descriptor):
            return descriptor.title
        case .success(let descriptor):
            return descriptor.title
        }
    }
    
    var description: String? {
        switch self {
        case .defaultError:
            return "Algo salió mal."
        case .custom(let descriptor):
            return descriptor.description
        case .success(let descriptor):
            return descriptor.description
        }
    }
    
    var image: Image {
        switch self {
        case .defaultError:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .custom(let descriptor):
            return descriptor.image?.image ?? Image(systemName: "exclamationmark.triangle.fill")
        case .success(let descriptor):
            return descriptor.image?.image ?? Image(systemName: "checkmark")
        }
    }
}


public extension View {
    @ViewBuilder
    func showToast(
        error: (type: ToastType?, showCloseButton: Bool, onDismiss: VoidClosure)?,
        isIdle: Bool,
        extraPadding: ToastPadding = ToastPadding.none,
        showAnimation: Bool = true
    ) -> some View {
        VStack {
            if isIdle {
                ZStack {
                    self
                    DefaultIdleView()
                }
            } else {
                if let error = error, let type = error.type {
                    self
                        .overlay(
                            ToastView(
                                type: type,
                                onDismiss: error.onDismiss,
                                showCloseButton: error.showCloseButton,
                                extraPadding: extraPadding,
                                showTransition: showAnimation
                            )
                        )
                } else {
                    self
                }
                
            }
        }
    }
}

