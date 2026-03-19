import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var isNotificationsPresented = false
    @State private var selectedDayTitle = ""
    @State private var selectedDayPayments: [Subscription] = []
    @State private var isDayPaymentsPresented = false
    @StateObject private var viewModel = CalendarViewModel(service: RealAPIService.shared)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    AndroidPageHeader(title: "Календарь", onNotifications: { isNotificationsPresented = true })
                    summaryCard
                    calendarCard

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(DS.Typography.caption)
                            .foregroundStyle(.red)
                    }

                    upcomingWeekSection
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
            .sheet(isPresented: $isDayPaymentsPresented) {
                DayPaymentsSheet(title: selectedDayTitle, payments: selectedDayPayments)
                    .presentationDetents([.medium, .large])
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
    CalendarView()
        .environmentObject(SessionManager.shared)
}

private extension CalendarView {
    var summaryCard: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.47, blue: 0.96),
                    Color(red: 0.02, green: 0.66, blue: 0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Всего в этом месяце")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.white.opacity(0.9))
                Text(AppDisplay.formatAmount(viewModel.totalAmount(in: viewModel.currentMonthDate()), currency: "RUB"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("\(viewModel.count(in: viewModel.currentMonthDate())) платежей")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 160)
    }

    var calendarCard: some View {
        AndroidCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(monthTitle(for: viewModel.currentMonthDate()))
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(DS.ColorToken.textPrimary)

                    Spacer()

                    HStack(spacing: 8) {
                        monthNavButton(systemName: "chevron.left") {
                            viewModel.setMonthOffset(viewModel.monthOffset - 1)
                        }
                        monthNavButton(systemName: "chevron.right") {
                            viewModel.setMonthOffset(viewModel.monthOffset + 1)
                        }
                    }
                }

                HStack {
                    ForEach(["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"], id: \.self) { title in
                        Text(title)
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                    ForEach(viewModel.daysForMonth()) { day in
                        CalendarDayTile(day: day) {
                            let payments = viewModel.payments(on: day.date)
                            guard !payments.isEmpty else { return }
                            selectedDayPayments = payments
                            selectedDayTitle = AppDisplay.formatDayTitle(day.date)
                            isDayPaymentsPresented = true
                        }
                    }
                }
            }
        }
    }

    var upcomingWeekSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Ближайшие 7 дней")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)

            if upcomingWeekSubscriptions.isEmpty {
                AndroidCard {
                    Text("Нет платежей в ближайшие 7 дней")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: DS.Spacing.sm) {
                    ForEach(upcomingWeekSubscriptions) { payment in
                        AndroidCard {
                            HStack(spacing: DS.Spacing.md) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.black.opacity(0.9))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Text(AppDisplay.firstLetter(from: payment.title))
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.white)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(payment.title)
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.ColorToken.textPrimary)
                                    Text(AppDisplay.daysUntilText(from: payment.nextBillingDate))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.ColorToken.textSecondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(AppDisplay.formatAmount(payment.amount, currency: payment.currency))
                                        .font(DS.Typography.headline)
                                        .foregroundStyle(DS.ColorToken.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.72)
                                    Text(formattedDate(for: payment))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.ColorToken.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    var upcomingWeekSubscriptions: [Subscription] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 6, to: today) else { return [] }

        return viewModel.subscriptions
            .compactMap { subscription -> (Subscription, Date)? in
                guard let date = AppDisplay.parseAPIDate(subscription.nextBillingDate) else { return nil }
                return (subscription, date)
            }
            .filter { $0.1 >= today && $0.1 <= end }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }

    func monthNavButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DS.ColorToken.textPrimary)
                .frame(width: 32, height: 32)
                .background(DS.ColorToken.cardBackground)
                .clipShape(Circle())
                .overlay(Circle().stroke(DS.ColorToken.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy 'г.'"
        return formatter.string(from: date)
    }

    func formattedDate(for subscription: Subscription) -> String {
        guard let date = AppDisplay.parseAPIDate(subscription.nextBillingDate) else {
            return "—"
        }
        return AppDisplay.formatShortDate(date)
    }
}

private struct CalendarDayTile: View {
    let day: CalendarDay
    let onTap: () -> Void

    var body: some View {
        let calendar = Calendar.current
        let isToday = calendar.isDate(day.date, inSameDayAs: Date())
        let hasPayments = day.paymentsCount > 0

        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(day.isInMonth ? (isToday ? DS.ColorToken.softPurple : DS.ColorToken.cardBackground) : DS.ColorToken.screenBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isToday ? DS.ColorToken.accent.opacity(0.5) : DS.ColorToken.border, lineWidth: 1)
                    )

                Text("\(calendar.component(.day, from: day.date))")
                    .font(DS.Typography.captionBold)
                    .foregroundStyle(day.isInMonth ? DS.ColorToken.textPrimary : DS.ColorToken.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(8)

                if hasPayments {
                    Circle()
                        .fill(DS.ColorToken.accent)
                        .frame(width: 8, height: 8)
                        .padding(8)
                }
            }
            .frame(height: 54)
        }
        .buttonStyle(.plain)
        .disabled(!hasPayments)
    }
}

private struct DayPaymentsSheet: View {
    let title: String
    let payments: [Subscription]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    Text(title)
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.ColorToken.textPrimary)

                    ForEach(payments) { payment in
                        AndroidCard {
                            HStack(spacing: DS.Spacing.md) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.black.opacity(0.9))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Text(AppDisplay.firstLetter(from: payment.title))
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.white)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(payment.title)
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.ColorToken.textPrimary)
                                    Text("Списание в этот день")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.ColorToken.textSecondary)
                                }

                                Spacer()

                                Text(AppDisplay.formatAmount(payment.amount, currency: payment.currency))
                                    .font(DS.Typography.headline)
                                    .foregroundStyle(DS.ColorToken.textPrimary)
                            }
                        }
                    }
                }
                .padding(DS.Spacing.md)
            }
            .background(DS.ColorToken.screenBackground)
            .navigationTitle("Платежи")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
