import SwiftUI

struct HomeView: View {
    @State private var isNotificationsPresented = false
    @State private var activeSheet: SheetDestination?
    @StateObject private var viewModel = HomeViewModel(service: MockAPIService.shared)

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
            .sheet(isPresented: $isNotificationsPresented) {
                NotificationsView()
            }
            .sheet(item: $activeSheet) { sheet in
                PlaceholderView(title: sheet.title)
            }
            .task {
                await viewModel.load()
            }
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
            Button(action: { isNotificationsPresented = true }) {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
        }
    }

    var totalCard: some View {
        ZStack(alignment: .topLeading) {
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
                Text(viewModel.summary?.totalMonthly ?? "—")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text(viewModel.summary?.changeText ?? "")
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(DS.Spacing.lg)
            .onTapGesture {
                activeSheet = SheetDestination(title: "Добавить подписку")
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
                Text(viewModel.summary?.upcomingAlert ?? "Нет ближайших списаний")
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
                value: viewModel.summary?.activeCount ?? "—"
            )
            .onTapGesture { activeSheet = SheetDestination(title: "Подписки") }
            StatCard(
                icon: "calendar",
                title: "Ближайший",
                value: viewModel.summary?.nextPayment ?? "—"
            )
            .onTapGesture { activeSheet = SheetDestination(title: "Ближайший платёж") }
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
                    .onTapGesture { activeSheet = SheetDestination(title: "Все платежи") }
            }

            VStack(spacing: DS.Spacing.sm) {
                ForEach(viewModel.upcomingPayments) { payment in
                    PaymentRow(title: payment.title, subtitle: payment.subtitle, amount: payment.amount, color: color(from: payment.colorName))
                        .onTapGesture { activeSheet = SheetDestination(title: payment.title) }
                }
            }
        }
    }

    var categoriesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Популярные категории")
                .font(DS.Typography.headline)
            HStack(spacing: DS.Spacing.md) {
                ForEach(viewModel.categories) { category in
                    CategoryChip(title: category.title, count: category.count)
                        .onTapGesture { activeSheet = SheetDestination(title: "Категория: \(category.title)") }
                }
            }
        }
    }

    func color(from name: String) -> Color {
        switch name {
        case "black": return .black
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }
}

private struct SheetDestination: Identifiable {
    let id = UUID()
    let title: String
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
