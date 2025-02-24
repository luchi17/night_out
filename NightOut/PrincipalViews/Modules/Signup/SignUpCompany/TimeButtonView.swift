import SwiftUI

struct TimeButtonView: View {
 
    var title: String
    @State private var showTimePicker: Bool = false
    @State private var selectedTime = Date()
    @State private var firstTime: Bool = true
    @Binding var selectedTimeString: String
    
    var body: some View {
        Button(action: {
//            firstTime = false
            showTimePicker.toggle()
        }) {
            Text(selectedTimeString.isEmpty ? title: selectedTimeString)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.grayColor)
                .cornerRadius(25)
        }
        .if(showTimePicker) { view in
            VStack {
                view
                DatePicker("Seleccione la hora", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .onChange(of: selectedTime, { _ , newValue in
                        selectedTimeString = timeString(from: selectedTime)
                    })
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(25)
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
