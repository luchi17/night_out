import SwiftUI
import Combine
import MessageUI

struct TicketsHistoryView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    
    @State private var showBottomSheet: Bool = false
    
    @ObservedObject var viewModel: TicketsHistoryViewModel
    let presenter: TicketsHistoryPresenter
    
    init(
        presenter: TicketsHistoryPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            if !viewModel.ticketsList.isEmpty {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach($viewModel.ticketsList, id: \.self) { ticket in
                            TicketHistoryRow(
                                ticket: ticket,
                                pdfToShow: $viewModel.ticketNumberToShow
                            )
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.top, 30)
        .padding(.horizontal, 20)
        .background(
            Color.blackColor
                .ignoresSafeArea()
        )
        .showCustomNavBar(
            title: "Mis tickets",
            goBack: goBackPublisher.send,
            image: {
                Image("ticket")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Color.white)
            }
        )
        .onChange(of: viewModel.ticketNumberToShow) { oldValue, newValue in
            if newValue != nil {
                self.showBottomSheet = true
            }
        }
        .sheet(isPresented: $showBottomSheet, onDismiss: {
            viewModel.ticketNumberToShow = nil
            showBottomSheet = false
        }) {
            if let ticketToShow = viewModel.ticketNumberToShow {
                TicketHistoryBottomSheet(
                    ticketNumberToShow: ticketToShow,
                    isPresented: $showBottomSheet
                )
                .presentationDetents([.fraction(0.8)])
            }
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
        .onAppear(perform: viewDidLoadPublisher.send)
    }
}

private extension TicketsHistoryView {
    
    func bindViewModel() {
        let input = TicketsHistoryPresenterImpl.Input(
            viewIsLoaded: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

struct TicketHistoryRow: View {
    
    @Binding var ticket: TicketHistoryPDFModel
    @Binding var pdfToShow: String?
   
    var body: some View {
        HStack {
            Image("ticket")
                .resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
                .foregroundStyle(Color.blackColor)
            
            Text("Evento - \(ticket.date)")
                .font(.headline)
                .foregroundStyle(Color.blackColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Image("pdf_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
                .onTapGesture {
                    pdfToShow = ticket.ticketNumber
                }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
    }
}
