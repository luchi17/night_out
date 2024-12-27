import SwiftUI
import Combine

struct NotificationsView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let onAcceptPublisher = PassthroughSubject<(String, String), Never>()
    private let onRejectPublisher = PassthroughSubject<(String, String), Never>()
    private let goToPostPublisher = PassthroughSubject<NotificationModelForView, Never>()
    private let goToProfilePublisher = PassthroughSubject<NotificationModelForView, Never>()
    
    @ObservedObject var viewModel: NotificationsViewModel
    let presenter: NotificationsPresenter
    
    init(
        presenter: NotificationsPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack(spacing: 0) {

            Text("Notificaciones")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .padding(.all, 12)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(Color.white)
                .frame(height: 2)
                .padding(.vertical, 4)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.notifications.reversed(), id: \.notificationId) { notification in
                        if notification.type == .friendRequest {
                            FriendRequestNotificationView(
                                notification: notification,
                                onAccept: onAcceptPublisher.send,
                                onReject: onRejectPublisher.send,
                                goToProfile: goToProfilePublisher.send
                            )
                        } else {
                            DefaultNotificationView(
                                notification: notification,
                                goToPost: goToPostPublisher.send,
                                goToProfile: goToProfilePublisher.send
                            )
                        }
                    }
                }
                .padding(.all, 12)
            }
            
            Spacer()
        }
        .showToast(
            error: (
                type: viewModel.toast,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toast = nil
                }
            ),
            isIdle: viewModel.loading
        )
        .background(Color.black.opacity(0.7))
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
}

private extension NotificationsView {
    func bindViewModel() {
        let input = NotificationsPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            accept: onAcceptPublisher.eraseToAnyPublisher(),
            reject: onRejectPublisher.eraseToAnyPublisher(),
            goToPost: goToPostPublisher.eraseToAnyPublisher(),
            goToProfile: goToProfilePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

