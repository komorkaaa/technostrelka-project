import SwiftUI

struct NotificationsView: View {
    var body: some View {
        NavigationStack {
            List {
                NotificationRow(
                    title: "Списание через 3 дня",
                    message: "Adobe Creative Cloud — 3 499 ₽",
                    time: "Сегодня"
                )
                NotificationRow(
                    title: "Новый платёж добавлен",
                    message: "Notion — 8 $",
                    time: "Вчера"
                )
                NotificationRow(
                    title: "Экономия за месяц",
                    message: "Вы сэкономили 1 240 ₽",
                    time: "2 дня назад"
                )
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Уведомления")
        }
    }
}

#Preview {
    NotificationsView()
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
