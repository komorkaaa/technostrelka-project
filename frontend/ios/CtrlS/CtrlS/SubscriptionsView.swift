import SwiftUI

struct SubscriptionsView: View {
    @State private var query = ""
    @State private var selectedTab: Tab = .all

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    searchBar
                    filterTabs
                    subscriptionsList
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.xl)
            }
            .background(DS.ColorToken.screenBackground)
            .navigationTitle("Подписки")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "bell")
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
            }
        }
    }
}

#Preview {
    SubscriptionsView()
}

private extension SubscriptionsView {
    enum Tab: String, CaseIterable {
        case all = "Все"
        case active = "Активные"
        case paused = "На паузе"
    }

    var searchBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DS.ColorToken.textSecondary)
                TextField("Поиск...", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(DS.ColorToken.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
            )

            Button(action: {}) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.ColorToken.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
                    )
            }
        }
    }

    var filterTabs: some View {
        HStack(spacing: DS.Spacing.sm) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.rawValue)
                        .font(DS.Typography.caption)
                        .foregroundStyle(selectedTab == tab ? .white : DS.ColorToken.textSecondary)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(selectedTab == tab ? DS.ColorToken.accent : DS.ColorToken.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
                        )
                }
            }
        }
    }

    var subscriptionsList: some View {
        VStack(spacing: DS.Spacing.sm) {
            SubscriptionRow(
                title: "Яндекс Плюс",
                subtitle: "Подписка на Яндекс Плюс с доступом к...",
                price: "399 ₽ / в месяц",
                status: "Активна",
                date: "20 мар."
            )
            SubscriptionRow(
                title: "Spotify",
                subtitle: "Премиум подписка на музыкальный сервис",
                price: "169 ₽ / в месяц",
                status: "Активна",
                date: "15 мар."
            )
            SubscriptionRow(
                title: "Adobe Creative Cloud",
                subtitle: "Полный пакет приложений Adobe",
                price: "3 499 ₽ / в месяц",
                status: "Активна",
                date: "25 мар."
            )
            SubscriptionRow(
                title: "Okko",
                subtitle: "Онлайн‑кинотеатр",
                price: "599 ₽ / в месяц",
                status: "Активна",
                date: "18 мар."
            )
            SubscriptionRow(
                title: "Notion",
                subtitle: "Сервис для организации работы",
                price: "8 $ / в месяц",
                status: "Активна",
                date: "12 мар."
            )
            SubscriptionRow(
                title: "Readymag",
                subtitle: "Конструктор сайтов",
                price: "16 $ / в месяц",
                status: "На паузе",
                date: "28 мар."
            )
        }
    }
}

private struct SubscriptionRow: View {
    let title: String
    let subtitle: String
    let price: String
    let status: String
    let date: String

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DS.ColorToken.chipBackground)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(title.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DS.ColorToken.accent)
                )
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.ColorToken.textPrimary)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
                Text(status)
                    .font(DS.Typography.caption)
                    .foregroundStyle(status == "На паузе" ? .orange : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(DS.ColorToken.chipBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(subtitle)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
                HStack {
                    Text(price)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.accent)
                    Spacer()
                    Text(date)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.ColorToken.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
        )
    }
}
