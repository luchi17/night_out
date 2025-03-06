import SwiftUI

struct CalendarPicker: View {
    @Binding var selectedDateFilter: TicketDateFilterType?
    
    @State private var selectedDate: Date?
    
    @Environment(\.dismiss) var dismiss
    
    private func formattedDate(_ date: Date) -> String {
        var calendar = Calendar.current
        
        let day = String(format: "%02d", calendar.component(.day, from: date))
        let month = String(format: "%02d", calendar.component(.month, from: date))
        let year = calendar.component(.year, from: date)
        return "\(day)-\(month)-\(year)"
    }
    
    private func obtenerRangoSemanaActual() -> (inicio: Date, fin: Date) {
        let calendar = Calendar.current
        let today = Date()

        // Obtener el primer día de la semana (lunes)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        // Obtener el último día de la semana (domingo)
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!

        return (startOfWeek, endOfWeek)
    }

    
    var body: some View {
        VStack {
            Picker("Opciones de fecha", selection: Binding<Date> (
                get: { selectedDate ?? Date() },
                set: { newValue in
                    selectedDate = newValue
                    let (inicioSemana, finSemana) = obtenerRangoSemanaActual()
                    
                    if newValue == Calendar.current.startOfDay(for: Date()) {
                        selectedDateFilter = .today
                    } else if newValue == Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                        selectedDateFilter = .tomorrow
                    } else if newValue >= inicioSemana && newValue <= finSemana {
                        selectedDateFilter = .week
                    } else {
                        selectedDateFilter = .day(formattedDate(newValue))
                    }
                })
            ) {
                Text("Hoy".uppercased()).tag(Calendar.current.startOfDay(for: Date()))
                Text("Mañana".uppercased()).tag(Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
                Text("Esta semana".uppercased()).tag(obtenerRangoSemanaActual().inicio)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            DatePicker("Selecciona una fecha", selection: Binding<Date> (
                get: { selectedDate ?? Date() },
                set: { newValue in
                    selectedDate = newValue
                    let (inicioSemana, finSemana) = obtenerRangoSemanaActual()
                    
                    if newValue >= inicioSemana && newValue <= finSemana {
                        selectedDateFilter = .week
                    } else {
                        selectedDateFilter = .day(formattedDate(newValue))
                    }
                }),
                displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()

            Button(action: {
                if selectedDate == nil {
                    selectedDate = Date()
                    selectedDateFilter = .today
                }
                dismiss()
            }) {
                Text("Escoger fecha".uppercased())
                    .foregroundStyle(.white)
            }
            .padding()
            
            Button("Cerrar") {
                selectedDate = nil
                selectedDateFilter = nil
                dismiss()
            }
            .padding()
        }
    }
}
