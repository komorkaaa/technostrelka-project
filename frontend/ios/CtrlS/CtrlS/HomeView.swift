import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    header
                    totalCard
                    upcomingCard
                    quickStats
                    paymentsSection
                    categoriesSection
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.xl)
            }
            .background(DS.ColorToken.screenBackground)
            .navigationTitle("Главная")
        }
    }
}

#Preview {
    HomeView()
}

private extension HomeView {
    var header: some View {
        HStack {
            Text("SubMonitor")
                .font(DS.Typography.title)
                .foregroundStyle(DS.ColorToken.accent)
            Spacer()
            Image(systemName: "bell")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DS.ColorToken.textSecondary)
        }
    }

    var totalCard: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [DS.ColorToken.accent, DS.ColorToken.accentDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))

            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Всего в месяц")
                    .font(DS.Typography.body)
                    .foregroundStyle(.white.opacity(0.9))
                Text("6 045 ₽")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text("+12% от прошлого месяца")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(DS.Spacing.lg)

            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(DS.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    var upcomingCard: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Скоро списание")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Text("Через 3 дня будет списано 3 499 ₽ за Adobe Creative Cloud")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
            Spacer()
        }
        .padding(DS.Spacing.md)
        .background(DS.ColorToken.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
        )
    }

    var quickStats: some View {
        HStack(spacing: DS.Spacing.md) {
            StatCard(
                icon: "creditcard",
                title: "Подписок",
                value: "7"
            )
            StatCard(
                icon: "calendar",
                title: "Ближайший",
                value: "-1 дн."
            )
        }
    }

    var paymentsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack {
                Text("Ближайшие платежи")
                    .font(DS.Typography.headline)
                Spacer()
                Button("Все") {}
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.accent)
            }

            VStack(spacing: DS.Spacing.sm) {
                PaymentRow(title: "Notion", subtitle: "Через 1 дн.", amount: "8 $", color: .black)
                PaymentRow(title: "Spotify", subtitle: "Через 2 дн.", amount: "169 ₽", color: .green)
                PaymentRow(title: "Okko", subtitle: "Через 5 дн.", amount: "599 ₽", color: .orange)
                PaymentRow(title: "Яндекс Плюс", subtitle: "Через 7 дн.", amount: "399 ₽", color: .red)
            }
        }
    }

    var categoriesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Популярные категории")
                .font(DS.Typography.headline)
            HStack(spacing: DS.Spacing.md) {
                CategoryChip(title: "Стриминг", count: "2")
                CategoryChip(title: "Музыка", count: "3")
                CategoryChip(title: "ПО", count: "4")
                CategoryChip(title: "Облако", count: "5")
            }
        }
    }
}

private struct StatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(DS.ColorToken.accent)
                .frame(width: 32, height: 32)
                .background(DS.ColorToken.chipBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
                Text(value)
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
            }
            Spacer()
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

private struct PaymentRow: View {
    let title: String
    let subtitle: String
    let amount: String
    let color: Color

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(title.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Text(subtitle)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
            Spacer()
            Text(amount)
                .font(DS.Typography.body)
                .foregroundStyle(DS.ColorToken.textPrimary)
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

private struct CategoryChip: View {
    let title: String
    let count: String

    var body: some View {
        VStack(spacing: 6) {
            Text(count)
                .font(DS.Typography.headline)
                .foregroundStyle(DS.ColorToken.accent)
                .frame(width: 44, height: 44)
                .background(DS.ColorToken.chipBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(title)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.ColorToken.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xs)
    }
}
