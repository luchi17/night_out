import SwiftUI

struct CalendarPicker: View {
    @Binding var selectedDateFilter: TicketDateFilterType?
    
    @State private var selectedDate: Date?
    
    @Environment(\.dismiss) var dismiss
    
    private func formattedDate(_ date: Date) -> String {
        let day = String(format: "%02d", Calendar.current.component(.day, from: date))
        let month = String(format: "%02d", Calendar.current.component(.month, from: date))
        let year = Calendar.current.component(.year, from: date)
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

                    let startOfNewValue = Calendar.current.startOfDay(for: newValue)
                    selectedDate = startOfNewValue
                    
                    let (inicioSemana, finSemana) = obtenerRangoSemanaActual()
                    
                    if Calendar.current.isDate(startOfNewValue, inSameDayAs: Date()) {
                        selectedDateFilter = .today
                    } else if Calendar.current.isDate(startOfNewValue, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: Date())!) {
                        selectedDateFilter = .tomorrow
                    } else if startOfNewValue >= inicioSemana && startOfNewValue <= finSemana {
                        selectedDateFilter = .week
                    } else {
                        selectedDateFilter = .day(formattedDate(newValue))
                    }
                })
            ) {
                Text("Hoy".uppercased()).tag(Calendar.current.startOfDay(for: Date()))
                Text("Mañana".uppercased()).tag(Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!))
                Text("Esta semana".uppercased()).tag(obtenerRangoSemanaActual().inicio)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            DatePicker("Selecciona una fecha", selection: Binding<Date> (
                get: { selectedDate ?? Date() },
                set: { newValue in
                    
                    let startOfNewValue = Calendar.current.startOfDay(for: newValue)
                    selectedDate = startOfNewValue
                    
                    if Calendar.current.isDate(startOfNewValue, inSameDayAs: Date()) {
                        selectedDateFilter = .today
                    } else if Calendar.current.isDate(startOfNewValue, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: Date())!) {
                        selectedDateFilter = .tomorrow
                    } else {
                        selectedDateFilter = .day(formattedDate(newValue))
                    }
                }),
                displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()

            Button("Escoger fecha".uppercased()) {
                if selectedDate == nil {
                    selectedDateFilter = .today
                }
                dismiss()
            }
            .padding()
            
            Button(action: {
                selectedDateFilter = nil
                dismiss()
            }) {
                Text("Cerrar")
                    .foregroundStyle(.white)
            }
            .padding()
        }
    }
}
