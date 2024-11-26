import SwiftUI

struct ToastView: View {
    var type: ToastType
    var onDismiss: VoidClosure?
    var showCloseButton: Bool = false
    
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            if isVisible {
                HStack(spacing: 20) {
                    type.image
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                        .padding(.leading, 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(type.title)
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(type.description)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                                .foregroundColor(.red)
                        }
                        .padding(.trailing, 20)
                    }
                }
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))  // Fondo azul claro
                .transition(.move(edge: .top))  // Transición desde arriba
                .zIndex(1)  // Asegura que el toast esté sobre otras vistas
            }
            Spacer()
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.linear) {
                    isVisible = false
                }
            }
        }
    }
}


public class ToastDescriptor {
    public let title: String
    public let description: String
    public let image: Image?
    
    init(title: String, description: String, image: Image?) {
        self.title = title
        self.description = description
        self.image = image
    }
}

public enum ToastType {
    case normal
    case custom(ToastDescriptor)
    
    var title: String {
        switch self {
        case .normal:
            return "Error"
        case .custom(let descriptor):
            return descriptor.title
        }
    }
    
    var description: String {
        switch self {
        case .normal:
            return "Algo salió mal."
        case .custom(let descriptor):
            return descriptor.description
        }
    }
    
    var image: Image {
        switch self {
        case .normal:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .custom(let descriptor):
            return descriptor.image ?? Image(systemName: "exclamationmark.triangle.fill")
        }
    }
}


public extension View {
    @ViewBuilder
    func showToast(
        error: (type: ToastType?, showCloseButton: Bool, onDismiss: VoidClosure)?,
        isIdle: Bool
    ) -> some View {
        VStack(spacing: 0) {
            if isIdle {
                ZStack(alignment: .top) {
                    self
//                        .opacity(0)
                    DefaultIdleView()
                }
            } else {
                if let error = error, let type = error.type {
                    self
                        .overlay(
                            Group {
                                ToastView(
                                    type: type,
                                    onDismiss: error.onDismiss,
                                    showCloseButton: error.showCloseButton
                                )
                            }
                        )
                } else {
                    self
                }
                
            }
        }
    }
}

