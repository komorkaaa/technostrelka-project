import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationStack {
            Text("Календарь")
                .font(.title)
                .navigationTitle("Календарь")
        }
    }
}

#Preview {
    CalendarView()
}
