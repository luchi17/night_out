import SwiftUI
import Combine
import MessageUI

struct PayPDFView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    private let openPDFPublisher = PassthroughSubject<TicketPDFModel, Never>()
    private let downloadPDFPublisher = PassthroughSubject<TicketPDFModel, Never>()
    
    @State private var mailResult: MFMailComposeResult?
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
                .padding(.top, 20)
            
            if !viewModel.ticketsList.isEmpty {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach($viewModel.ticketsList, id: \.self) { ticket in
                            PDFTicketRow(
                                ticket: ticket,
                                pdfToShow: $viewModel.pdfToShow
                            )
                        }
                    }
                }
                .padding(.top, 30)
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
        .sheet(isPresented: $viewModel.isShowingMailComposer) {
            MailComposerView(
                destinatario: viewModel.emailPdf,
                pdfFileURL: viewModel.pdfString!) { result in
                    mailResult = result
                    handleMailResult(result)
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
            viewIsLoaded: viewDidLoadPublisher.eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher(),
            openPDf: openPDFPublisher.eraseToAnyPublisher(),
            downloadPdf: downloadPDFPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
    
    func handleMailResult(_ result: MFMailComposeResult) {
        switch result {
        case .sent:
            print("Correo enviado con éxito.")
        case .failed:
            print("Error al enviar el correo.")
        case .cancelled:
            print("Correo cancelado.")
        case .saved:
            print("Correo guardado como borrador.")
        @unknown default:
            print("Resultado desconocido.")
        }
    }
    
}


struct PDFTicketRow: View {
    
    @Binding var ticket: TicketPDFModel
    @Binding var pdfToShow: URL?
   
    var body: some View {
        HStack {
            Image("ticket")
                .resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
                .foregroundStyle(Color.blackColor)
                .padding(.trailing)
            
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
                    .offset(y: -3)
            }
        }
        .padding(12)
        .background(Color.white)
    }
}
