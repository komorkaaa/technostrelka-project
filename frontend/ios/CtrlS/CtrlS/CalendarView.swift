import SwiftUI

struct CalendarView: View {
    @State private var isNotificationsPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    monthCard
                    calendarCard
                    upcomingSection
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.xl)
            }
            .background(DS.ColorToken.screenBackground)
            .navigationTitle("Календарь")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isNotificationsPresented = true }) {
                        Image(systemName: "bell")
                            .foregroundStyle(DS.ColorToken.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $isNotificationsPresented) {
                NotificationsView()
            }
        }
    }
}

#Preview {
    CalendarView()
}

private extension CalendarView {
    var monthCard: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.45, blue: 0.96),
                         Color(red: 0.03, green: 0.65, blue: 0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))

            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Всего в этом месяце")
                    .font(DS.Typography.body)
                    .foregroundStyle(.white.opacity(0.9))
                Text("6 045 ₽")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text("7 платежей")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(DS.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    var calendarCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack {
                Text("Март 2026")
                    .font(DS.Typography.headline)
                Spacer()
                HStack(spacing: 8) {
                    navButton(system: "chevron.left")
                    navButton(system: "chevron.right")
                }
            }
            CalendarGrid()
        }
        .padding(DS.Spacing.md)
        .background(DS.ColorToken.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
        )
    }

    var upcomingSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Ближайшие 7 дней")
                .font(DS.Typography.headline)
            VStack(spacing: DS.Spacing.sm) {
                PaymentRow(title: "Spotify", subtitle: "Через 2 дн.", amount: "169 ₽", color: .green)
                PaymentRow(title: "Okko", subtitle: "Через 5 дн.", amount: "599 ₽", color: .orange)
                PaymentRow(title: "Яндекс Плюс", subtitle: "Через 7 дн.", amount: "399 ₽", color: .red)
            }
        }
    }

    func navButton(system: String) -> some View {
        Image(systemName: system)
            .font(.system(size: 12, weight: .bold))
            .frame(width: 28, height: 28)
            .background(DS.ColorToken.chipBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CalendarGrid: View {
    private let weekDays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    private let days = Array(1...31)

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(0..<2, id: \.self) { _ in
                    Color.clear
                        .frame(height: 28)
                }
                ForEach(days, id: \.self) { day in
                    Text("\(day)")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(day == 13 ? DS.ColorToken.accent.opacity(0.2) : DS.ColorToken.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
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
