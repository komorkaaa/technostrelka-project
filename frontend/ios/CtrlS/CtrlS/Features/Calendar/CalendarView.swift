import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var isNotificationsPresented = false
    @State private var activeSheet: SheetDestination?
    @StateObject private var viewModel = CalendarViewModel(service: RealAPIService.shared)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    monthCard
                    calendarCard
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(DS.Typography.caption)
                            .foregroundStyle(.red)
                    }
                    dayPaymentsSection
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
            .sheet(item: $activeSheet) { sheet in
                PlaceholderView(title: sheet.title)
            }
            .task(id: session.accessToken) { await viewModel.load() }
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(SessionManager.shared)
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
                Text(formatAmount(viewModel.totalAmount(in: viewModel.currentMonthDate())))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(viewModel.count(in: viewModel.currentMonthDate())) платежей")
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
                Text(monthTitle(for: viewModel.currentMonthDate()))
                    .font(DS.Typography.headline)
                Spacer()
                Button("Сегодня") {
                    viewModel.setMonthOffset(0)
                    viewModel.selectedDate = Date()
                }
                .font(DS.Typography.caption)
                .foregroundStyle(DS.ColorToken.accent)
                HStack(spacing: 8) {
                    navButton(system: "chevron.left", title: "Предыдущий месяц", action: {
                        viewModel.setMonthOffset(viewModel.monthOffset - 1)
                    })
                    navButton(system: "chevron.right", title: "Следующий месяц", action: {
                        viewModel.setMonthOffset(viewModel.monthOffset + 1)
                    })
                }
            }
            CalendarGrid(
                days: viewModel.daysForMonth(),
                selectedDate: viewModel.selectedDate,
                onSelect: { date in viewModel.selectedDate = date }
            )
        }
        .padding(DS.Spacing.md)
        .background(DS.ColorToken.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
        )
    }

    var dayPaymentsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Платежи на \(dayTitle(for: viewModel.selectedDate))")
                .font(DS.Typography.headline)
            VStack(spacing: DS.Spacing.sm) {
                let payments = viewModel.payments(on: viewModel.selectedDate)
                if payments.isEmpty {
                    Text("Нет списаний на выбранную дату")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
                ForEach(payments) { payment in
                    PaymentRow(
                        title: payment.title,
                        subtitle: payment.subtitle,
                        amount: payment.price,
                        color: color(from: payment.status == .paused ? "orange" : "purple")
                    )
                    .onTapGesture { activeSheet = SheetDestination(title: payment.title) }
                }
            }
        }
    }

    func navButton(system: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 28, height: 28)
                .background(DS.ColorToken.chipBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }

    func dayTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }

    func color(from name: String) -> Color {
        switch name {
        case "black": return .black
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "blue": return .blue
        case "purple": return .purple
        default: return .gray
        }
    }

    func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "ru_RU")
        let base = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(base) ₽"
    }
}

private struct SheetDestination: Identifiable {
    let id = UUID()
    let title: String
}

private struct CalendarGrid: View {
    private let weekDays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    let days: [CalendarDay]
    let selectedDate: Date
    let onSelect: (Date) -> Void

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
                ForEach(days) { day in
                    CalendarDayCell(
                        day: day,
                        isSelected: Calendar.current.isDate(day.date, inSameDayAs: selectedDate),
                        onSelect: onSelect
                    )
                }
            }
        }
    }
}

private struct CalendarDayCell: View {
    let day: CalendarDay
    let isSelected: Bool
    let onSelect: (Date) -> Void

    var body: some View {
        Button(action: { onSelect(day.date) }) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(DS.Typography.caption)
                    .foregroundStyle(day.isInMonth ? DS.ColorToken.textPrimary : DS.ColorToken.textSecondary)
                if day.paymentsCount > 0 {
                    Circle()
                        .fill(DS.ColorToken.accent)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(isSelected ? DS.ColorToken.accent.opacity(0.2) : DS.ColorToken.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
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
