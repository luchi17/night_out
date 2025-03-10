import SwiftUI
import Combine
import MessageUI

struct PayPDFView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    private let openPDFPublisher = PassthroughSubject<TicketPDFModel, Never>()
    private let downloadPDFPublisher = PassthroughSubject<TicketPDFModel, Never>()
    
    @State private var showPDF: Bool = false
    
    @ObservedObject var viewModel: PayPDFViewModel
    let presenter: PayPDFPresenter
    
    init(
        presenter: PayPDFPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            
            Image("logo_amarillo")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
            
            Text("¡Disfruta de tu evento!")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 10)
            
            if !viewModel.ticketsList.isEmpty {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach($viewModel.ticketsList, id: \.self) { ticket in
                            PDFTicketRow(
                                ticket: ticket,
                                pdfToShow: $viewModel.pdfToShow,
                                download: downloadPDFPublisher.send
                            )
                        }
                    }
                }
                .padding(.top, 20)
            }
            
            Spacer()
        }
        .padding(.top, 30)
        .background(
            Color.blackColor
                .ignoresSafeArea()
        )
        .showCustomNavBar(
            title: "Entradas",
            goBack: goBackPublisher.send
        )
        .onChange(of: viewModel.pdfToShow) { oldValue, newValue in
            if newValue != nil {
                showPDF = true
            }
        }
        .sheet(isPresented: $showPDF, onDismiss: {
            viewModel.pdfToShow = nil
            showPDF = false
        }) {
            if let pdfToShow = viewModel.pdfToShow {
                PDFKitView(url: pdfToShow)
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

private extension PayPDFView {
    
    func bindViewModel() {
        let input = PayPDFPresenterImpl.Input(
            viewIsLoaded: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher(),
            openPDf: openPDFPublisher.eraseToAnyPublisher(),
            downloadPdf: downloadPDFPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}


struct PDFTicketRow: View {
    
    @Binding var ticket: TicketPDFModel
    @Binding var pdfToShow: URL?
    var download: InputClosure<TicketPDFModel>
   
    var body: some View {
        HStack {
            Image("ticket")
                .resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
                .foregroundStyle(Color.blackColor)
            
            Text("Entrada - \(ticket.name)")
                .font(.headline)
                .foregroundStyle(Color.blackColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Image("pdf_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
                .onTapGesture {
                    pdfToShow = ticket.pdf
                }
            
            ZStack(alignment: .bottom) {
                Image(systemName: "arrow.down")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(Color.blackColor)
                
                Rectangle()
                    .frame(width: 20, height: 3)
                    .foregroundColor(Color.blackColor)
                    .padding(.bottom, 0)
                    .offset(y: 3)
            }
            .onTapGesture {
                download(ticket)
            }
        }
        .padding(12)
        .background(Color.white)
    }
}
