import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Text("Профиль")
                .font(.title)
                .navigationTitle("Профиль")
        }
    }
}

#Preview {
    ProfileView()
}
