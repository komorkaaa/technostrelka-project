import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NotificationsViewModel(service: RealAPIService.shared)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    HStack {
                        Text("Уведомления")
                            .font(DS.Typography.title)
                            .foregroundStyle(DS.ColorToken.textPrimary)
                        Spacer()
                        Button("Закрыть") { dismiss() }
                            .font(DS.Typography.captionBold)
                            .foregroundStyle(DS.ColorToken.accent)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(DS.Typography.caption)
                            .foregroundStyle(.red)
                    }

                    if viewModel.notifications.isEmpty && viewModel.errorMessage == nil {
                        AndroidCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Пока пусто")
                                    .font(DS.Typography.headline)
                                    .foregroundStyle(DS.ColorToken.textPrimary)
                                Text("Когда появятся ближайшие списания, они будут показаны здесь.")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.ColorToken.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        VStack(spacing: DS.Spacing.sm) {
                            ForEach(viewModel.notifications) { item in
                                NotificationRow(
                                    title: item.title,
                                    message: item.message,
                                    time: item.time
                                )
                            }
                        }
                    }
                }
                .padding(DS.Spacing.md)
            }
            .background(DS.ColorToken.screenBackground)
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
        AndroidCard {
            HStack(alignment: .top, spacing: 12) {
                AndroidIconTile(
                    systemName: "bell.fill",
                    foreground: DS.ColorToken.warning,
                    background: DS.ColorToken.softOrange
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.ColorToken.textPrimary)
                    Text(message)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                    Text(time)
                        .font(DS.Typography.captionBold)
                        .foregroundStyle(DS.ColorToken.accent)
                }

                Spacer()
            }
        }
    }
}
