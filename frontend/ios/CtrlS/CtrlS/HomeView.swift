import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            Text("Главная")
                .font(.title)
                .navigationTitle("Главная")
        }
    }
}

#Preview {
    HomeView()
}
