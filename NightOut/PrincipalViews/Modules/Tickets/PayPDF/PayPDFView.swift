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
    @State private var pdfToShow: URL?
    
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
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach($viewModel.ticketsList, id: \.self) { ticket in
                        PDFTicketRow(
                            ticket: ticket,
                            showPDF: $showPDF,
                            pdfToShow: $pdfToShow
                        )
                    }
                }
            }
            
            Spacer()
        }
        .background(
            Color.blackColor
        )
        .showCustomNavBar(
            title: "Entradas",
            goBack: goBackPublisher.send
        )
        .sheet(isPresented: $showPDF) {
            PDFKitView(url: viewModel.pdfString!)
                .scaledToFill()
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
    
    @Binding var showPDF: Bool
    @Binding var pdfToShow: URL?
   
    var body: some View {
        HStack {
            Image("ticket")
                .resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
                .foregroundStyle(Color.blackColor)
                .padding()
            
            Text("Entrada - \(ticket.name)")
                .font(.headline)
            
            Spacer()
            
            Image("pdf_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
            
            ZStack(alignment: .bottom) {
                Image(systemName: "arrow.down") //.circle.fill
                    .resizable()
                    .scaledToFill()
                    .frame(width: 35, height: 35)
                
                Rectangle()
                    .frame(width: 35, height: 3)
                    .foregroundColor(Color.blackColor)
            }
            .onTapGesture {
                pdfToShow = ticket.pdf
                showPDF = true
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
