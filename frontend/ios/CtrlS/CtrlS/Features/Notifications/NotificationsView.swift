import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = NotificationsViewModel(service: RealAPIService.shared)

    var body: some View {
        NavigationStack {
            List {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(DS.Typography.caption)
                        .foregroundStyle(.red)
                }
                ForEach(viewModel.notifications) { item in
                    NotificationRow(
                        title: item.title,
                        message: item.message,
                        time: item.time
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Уведомления")
            .task(id: session.accessToken) { await viewModel.load() }
        }
    }
}

#Preview {
    NotificationsView()
        .environmentObject(SessionManager.shared)
}

private struct NotificationRow: View {
    let title: String
    let message: String
    let time: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DS.Typography.body)
                .foregroundStyle(DS.ColorToken.textPrimary)
            Text(message)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.ColorToken.textSecondary)
            Text(time)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.ColorToken.textSecondary)
        }
        .padding(.vertical, 4)
    }
}
