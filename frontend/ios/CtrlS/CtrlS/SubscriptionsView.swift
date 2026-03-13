import SwiftUI

struct SubscriptionsView: View {
    var body: some View {
        NavigationStack {
            Text("Подписки")
                .font(.title)
                .navigationTitle("Подписки")
        }
    }
}

#Preview {
    SubscriptionsView()
}
