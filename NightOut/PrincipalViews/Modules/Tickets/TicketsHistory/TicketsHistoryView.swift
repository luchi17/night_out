import SwiftUI
import Combine
import MessageUI

struct TicketsHistoryView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    
    @State private var showBottomSheet: Bool = false
    @State private var showPDF: Bool = false
    
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
        ZStack {
            Color.blackColor
                .ignoresSafeArea()
            
            if !viewModel.ticketsList.isEmpty {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach($viewModel.ticketsList, id: \.self) { ticket in
                            TicketHistoryRow(
                                ticket: ticket,
                                bottomSheetToShow: $viewModel.bottomSheetToShow,
                                pdfToShow: $viewModel.ticketToShow
                            )
                        }
                    }
                }
                .padding(.top, 30)
                .padding(.horizontal, 20)
            } else {
                Spacer()
                Text("Aún no tienes tickets.")
                    .foregroundStyle(.white)
                    .font(.headline)
            }
            
            Spacer()
        }
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
        .onChange(of: viewModel.ticketToShow) { oldValue, newValue in
            if newValue != nil {
                self.showPDF = true
            }
        }
        .onChange(of: viewModel.bottomSheetToShow) { oldValue, newValue in
            if newValue != nil {
                self.showBottomSheet = true
            }
        }
        .sheet(isPresented: $showBottomSheet, onDismiss: {
            viewModel.bottomSheetToShow = nil
            showBottomSheet = false
        }) {
            if let bottomSheetToShow = viewModel.bottomSheetToShow {
                TicketHistoryBottomSheet(
                    ticketNumberToShow: bottomSheetToShow,
                    isPresented: $showBottomSheet
                )
                .presentationDetents([.fraction(0.8)])
            }
        }
        .sheet(isPresented: $showPDF, onDismiss: {
            viewModel.ticketToShow = nil
            showPDF = false
        }) {
            if let url = viewModel.ticketToShow?.url {
                PDFKitView(url: url)
                    .scaledToFill()
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
    @Binding var bottomSheetToShow: String?
    @Binding var pdfToShow: TicketHistoryPDFModel?
   
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
                    pdfToShow = ticket
                }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .onTapGesture {
            bottomSheetToShow = ticket.ticketNumber
        }
    }
}
