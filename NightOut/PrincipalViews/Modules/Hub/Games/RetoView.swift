import SwiftUI

struct RetosView: View {
    
    @State private var challengeText: String?
    
    var body: some View {
        VStack {
            if let challengeText = challengeText {
                
                Text("\(challengeText)")
                    .font(.largeTitle)
                    .padding()
                    .onAppear {
                        withAnimation(.easeIn(duration: 2)) {}
                    }
                
                Spacer()
                
                Button(action: {
                    self.challengeText = nil
                }) {
                    Text("Volver".uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                
            } else {
                
                RuletaSubview(names: $retosDeBeber, showNames: false) { winner in
                    showRandomChallenge()
                }
                .padding()
            }
        }
        .padding()
    }
    
    private func showRandomChallenge() {
        challengeText = retosDeBeber.randomElement()?.0
    }
    
    
    @State var retosDeBeber = [
        "Bebe 2 sorbos si alguna vez has enviado un mensaje de texto que luego te arrepentiste.",
        "Elige a alguien para que beba 3 sorbos contigo.",
        "Haz un brindis por la persona a tu derecha y ambos beben.",
        "Bebe si alguna vez has fingido estar ocupado para evitar a alguien.",
        "Canta el estribillo de una canción aleatoria o bebe 3 sorbos.",
        "Haz una imitación de alguien del grupo, si adivinan quién es, bebes.",
        "Cuenta una historia vergonzosa o bebe 4 sorbos.",
        "El último en tocarse la nariz bebe 2 sorbos.",
        "Bebe si alguna vez has enviado un mensaje a la persona equivocada.",
        "Baila durante 30 segundos o bebe 3 sorbos.",
        "Habla con acento hasta tu siguiente turno o bebe 2 sorbos.",
        "Haz una confesión picante o bebe 4 sorbos.",
        "Muestra la última foto en tu galería o bebe 3 sorbos.",
        "Elige a alguien para que tome un trago cada vez que bebas durante los próximos 5 minutos.",
        "Haz un reto de flexibilidad (como tocarte los pies sin doblar las rodillas) o bebe.",
        "Di un cumplido sincero a la persona a tu izquierda o bebe 2 sorbos.",
        "Bebe si alguna vez has stalkeado a alguien en redes sociales.",
        "Ponte un objeto en la cabeza y equilíbralo durante 10 segundos o bebe.",
        "Elige a alguien para que haga 5 sentadillas, si no lo hace, bebe 2 sorbos.",
        "Bebe si alguna vez te has dormido en una fiesta.",
        
        // Retos para conocer mejor a la gente
        "Cuenta tu peor cita o bebe 3 sorbos.",
        "Pregunta a alguien del grupo qué es lo más loco que ha hecho y bebe si te sorprende.",
        "Revela tu mayor crush de celebridades o bebe 2 sorbos.",
        "Siéntate con alguien nuevo durante los próximos 5 minutos o bebe 2 sorbos.",
        "Cuenta el momento más vergonzoso que recuerdes de tu adolescencia o bebe 3 sorbos.",
        "Di algo que siempre hayas querido decirle a alguien aquí o bebe 4 sorbos.",
        "Comparte tu peor experiencia en el amor o bebe 3 sorbos.",
        "Haz una ronda de '¿Verdadero o Falso?' sobre ti mismo y deja que el grupo adivine. Quien falle, bebe.",
        "Cuenta tu mejor experiencia de viaje o bebe 2 sorbos.",
        "Pregunta a alguien sobre su infancia y comparte algo de la tuya o bebe 3 sorbos.",
        "Cuenta algo que nadie en la mesa sepa de ti o bebe 3 sorbos.",
        
        // Retos para conocer gente nueva
        "Ve con un desconocido y preséntate de una forma original o bebe 3 sorbos.",
        "Pide el Instagram o número de alguien desconocido y enséñalo al grupo o bebe 3 sorbos.",
        "Pregúntale a un desconocido por su signo del zodiaco y cuéntale el tuyo o bebe 2 sorbos.",
        "Haz un brindis con alguien que no conozcas bien o bebe 2 sorbos.",
        "Ve con un desconocido y dile que tiene buena energía, si responde bien, elige a alguien más para beber.",
        "Pregúntale a un desconocido cuál ha sido su mejor noche de fiesta y cuéntasela al grupo o bebe 3 sorbos.",
        "Pídele a alguien que elija una canción para el grupo y que explique por qué le gusta, si no acepta, bebes tú.",
        "Baila con alguien que no conozcas bien o bebe 3 sorbos.",
        "Ve con un desconocido y hazle una pregunta al azar sobre su vida o bebe 3 sorbos.",
        "Ve con alguien nuevo y pregúntale su película favorita. Si no la has visto, agrégala a tu lista y bebe 2 sorbos."
    ].map({ reto in
        let color = Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
        return (reto, color)
    })
    
}
