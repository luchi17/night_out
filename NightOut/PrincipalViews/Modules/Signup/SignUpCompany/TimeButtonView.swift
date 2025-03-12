import SwiftUI

struct TimeButtonView: View {
 
    var title: String
    @State private var showTimePicker: Bool = false
    @State private var selectedTime = Date()
    @State private var firstTime: Bool = true
    @Binding var selectedTimeString: String
    
    var verticalPadding: CGFloat = 8

    var body: some View {
        Button(action: {
            showTimePicker.toggle()
        }) {
            Text(selectedTimeString.isEmpty ? title: selectedTimeString)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, verticalPadding)
                .background(Color.grayColor)
                .cornerRadius(25)
        }
        .if(showTimePicker) { view in
            VStack {
                view
                DatePicker("Seleccione la hora", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .frame(width: 150, height: 150)
                    .labelsHidden()
                    .onChange(of: selectedTime, { _ , newValue in
                        selectedTimeString = timeString(from: selectedTime)
                    })
                    .padding()
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(25)
                    .shadow(radius: 25)
                    .transition(.move(edge: .top))
            }
        }
    }
    
    // Formatear la fecha en una cadena de hora:minuto
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
