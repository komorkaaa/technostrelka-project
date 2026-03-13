import SwiftUI

struct AnalyticsView: View {
    var body: some View {
        NavigationStack {
            Text("Аналитика")
                .font(.title)
                .navigationTitle("Аналитика")
        }
    }
}

#Preview {
    AnalyticsView()
}
