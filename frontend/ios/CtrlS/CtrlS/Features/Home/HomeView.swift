import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var isNotificationsPresented = false
    @State private var isCreatePresented = false
    @State private var selectedSubscription: Subscription?
    @State private var activeSheet: SheetDestination?
    @State private var selectedPeriod: DashboardPeriod = .month
    @State private var showAllPayments = false
    @StateObject private var viewModel = HomeViewModel(service: RealAPIService.shared)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    AndroidPageHeader(title: "CtrlS", onNotifications: { isNotificationsPresented = true })

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    heroCard
                    periodSelector

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(DS.Typography.caption)
                            .foregroundStyle(.red)
                    }

                    if let alert = viewModel.summary?.upcomingAlert, !viewModel.upcomingPayments.isEmpty {
                        soonChargeCard(text: alert)
                    }

                    statsRow
                    paymentsSection
                    categoriesSection
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, 96)
            }
            .background(DS.ColorToken.screenBackground)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isNotificationsPresented) {
                NotificationsView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isCreatePresented) {
                SubscriptionFormView(mode: .create) { payload in
                    _ = try await RealAPIService.shared.createSubscription(payload)
                    await viewModel.load()
                }
                .presentationDetents([.large])
            }
            .sheet(item: $selectedSubscription) { subscription in
                SubscriptionDetailView(
                    subscription: subscription,
                    onEdit: { activeSheet = SheetDestination(title: "Редактирование подписки") },
                    onDelete: { activeSheet = SheetDestination(title: "Удаление подписки") }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $activeSheet) { sheet in
                PlaceholderView(title: sheet.title)
                    .presentationDetents([.medium])
            }
            .task(id: session.accessToken) {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionManager.shared)
}

private extension HomeView {
    var heroCard: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [DS.ColorToken.accent, DS.ColorToken.accentPink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                Text(selectedPeriod.heroTitle)
                    .font(DS.Typography.caption)
                    .foregroundStyle(.white.opacity(0.92))

                Text(viewModel.projectedTotal(months: selectedPeriod.months))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Rectangle()
                    .fill(.white.opacity(0.24))
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Активных")
                        .font(DS.Typography.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(viewModel.summary?.activeCount ?? "0")
                        .font(DS.Typography.headline)
                        .foregroundStyle(.white)
                }
            }
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { isCreatePresented = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.18))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(DS.Spacing.md)
        }
        .frame(maxWidth: .infinity, minHeight: 184)
    }

    var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(DashboardPeriod.allCases, id: \.self) { period in
                    Button(action: { selectedPeriod = period }) {
                        AndroidFilterChip(title: period.label, isSelected: selectedPeriod == period)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func soonChargeCard(text: String) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            AndroidIconTile(systemName: "exclamationmark", foreground: DS.ColorToken.warning, background: DS.ColorToken.softOrange, size: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text("Скоро списание")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Text(text)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(DS.Spacing.md)
        .background(DS.ColorToken.softOrange.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(DS.ColorToken.warning.opacity(0.35), lineWidth: 1)
        )
    }

    var statsRow: some View {
        HStack(spacing: DS.Spacing.sm) {
            AndroidCard {
                HStack(spacing: 10) {
                    AndroidIconTile(systemName: "wallet.pass", foreground: DS.ColorToken.infoBlue, background: DS.ColorToken.softBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Подписок")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                        Text("\(viewModel.allSubscriptions.count)")
                            .font(DS.Typography.headline)
                            .foregroundStyle(DS.ColorToken.textPrimary)
                    }
                    Spacer()
                }
            }

            AndroidCard {
                HStack(spacing: 10) {
                    AndroidIconTile(systemName: "calendar", foreground: DS.ColorToken.warning, background: DS.ColorToken.softOrange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ближайший")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                        Text(viewModel.summary?.nextPayment ?? "—")
                            .font(DS.Typography.headline)
                            .foregroundStyle(DS.ColorToken.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    Spacer()
                }
            }
        }
    }

    var paymentsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                Text("Ближайшие платежи")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Spacer()
                if viewModel.upcomingPayments.count > 3 {
                    Button(showAllPayments ? "Свернуть" : "Показать все") {
                        showAllPayments.toggle()
                    }
                    .font(DS.Typography.captionBold)
                    .foregroundStyle(DS.ColorToken.accent)
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: DS.Spacing.sm) {
                if viewModel.upcomingPayments.isEmpty {
                    AndroidCard {
                        Text("Нет ближайших списаний")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ForEach(viewModel.visibleUpcomingPayments(showAll: showAllPayments)) { payment in
                        AndroidCard {
                            Button(action: {
                                selectedSubscription = viewModel.allSubscriptions.first { $0.title == payment.title }
                            }) {
                                HStack(spacing: DS.Spacing.md) {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.black.opacity(0.92))
                                        .frame(width: 46, height: 46)
                                        .overlay(
                                            Text(AppDisplay.firstLetter(from: payment.title))
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundStyle(.white)
                                        )

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(payment.title)
                                            .font(DS.Typography.body)
                                            .foregroundStyle(DS.ColorToken.textPrimary)
                                        Text(payment.subtitle)
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.ColorToken.textSecondary)
                                    }

                                    Spacer()

                                    Text(payment.amount)
                                        .font(DS.Typography.headline)
                                        .foregroundStyle(DS.ColorToken.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.72)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    var categoriesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Популярные категории")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)

            if viewModel.categories.isEmpty {
                AndroidCard {
                    Text("Категории появятся после добавления подписок")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: DS.Spacing.sm)], spacing: DS.Spacing.sm) {
                    ForEach(viewModel.categories) { category in
                        AndroidCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(category.count)
                                    .font(DS.Typography.headline)
                                    .foregroundStyle(DS.ColorToken.accent)
                                    .frame(width: 34, height: 34)
                                    .background(DS.ColorToken.softPurple)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                Text(category.title)
                                    .font(DS.Typography.captionBold)
                                    .foregroundStyle(DS.ColorToken.textPrimary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.75)
                            }
                            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
                        }
                    }
                }
            }
        }
    }
}

private struct SheetDestination: Identifiable {
    let id = UUID()
    let title: String
}

private enum DashboardPeriod: CaseIterable {
    case month
    case halfYear
    case year

    var label: String {
        switch self {
        case .month:
            return "Месяц"
        case .halfYear:
            return "Полгода"
        case .year:
            return "Год"
        }
    }

    var heroTitle: String {
        switch self {
        case .month:
            return "Прогноз за месяц"
        case .halfYear:
            return "Прогноз за полгода"
        case .year:
            return "Прогноз за год"
        }
    }

    var months: Int {
        switch self {
        case .month:
            return 1
        case .halfYear:
            return 6
        case .year:
            return 12
        }
    }
}
