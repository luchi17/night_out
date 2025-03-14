import SwiftUI
import Combine

struct NotificationsView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let onAcceptPublisher = PassthroughSubject<(String, String), Never>()
    private let onRejectPublisher = PassthroughSubject<(String, String), Never>()
    private let goToPostPublisher = PassthroughSubject<NotificationModelForView, Never>()
    private let goToProfilePublisher = PassthroughSubject<NotificationModelForView, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    
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
        
        ZStack {
            Color.blackColor.ignoresSafeArea()
            
            VStack(spacing: 0) {

                if !viewModel.loading {
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
                    .scrollIndicators(.hidden)
                }
               
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
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
        .showCustomNavBar(
            title: "Notificaciones",
            goBack: goBackPublisher.send
        )
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
            goToProfile: goToProfilePublisher.eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

