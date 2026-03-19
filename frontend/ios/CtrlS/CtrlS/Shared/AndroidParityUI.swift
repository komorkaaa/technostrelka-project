import SwiftUI

struct AndroidPageHeader: View {
    let title: String
    var accentTitle: Bool = true
    var onNotifications: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Text(title)
                .font(DS.Typography.title)
                .foregroundStyle(accentTitle ? DS.ColorToken.accent : DS.ColorToken.textPrimary)

            Spacer()

            if let onNotifications {
                Button(action: onNotifications) {
                    Image(systemName: "bell")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DS.ColorToken.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(DS.ColorToken.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(DS.ColorToken.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AndroidCard<Content: View>: View {
    var padding: CGFloat = DS.Spacing.md
    var cornerRadius: CGFloat = DS.Radius.md
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(DS.ColorToken.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(DS.ColorToken.border, lineWidth: 1)
            )
            .shadow(color: DS.ColorToken.cardShadow, radius: 10, y: 3)
    }
}

struct AndroidIconTile: View {
    let systemName: String
    let foreground: Color
    let background: Color
    var size: CGFloat = 38

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(background)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(foreground)
            )
    }
}

struct AndroidSectionCaption: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(DS.Typography.captionBold)
            .foregroundStyle(DS.ColorToken.textSecondary)
    }
}

struct AndroidFilterChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(DS.Typography.captionBold)
            .foregroundStyle(isSelected ? DS.ColorToken.accent : DS.ColorToken.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? DS.ColorToken.softPurple : DS.ColorToken.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : DS.ColorToken.border, lineWidth: 1)
            )
    }
}

enum AppDisplay {
    static func formatAmount(_ value: Double, currency: String = "RUB") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "ru_RU")
        let base = formatter.string(from: NSNumber(value: value)) ?? "\(value)"

        switch currency.uppercased() {
        case "RUB":
            return "\(base) ₽"
        case "USD":
            return "\(base) $"
        case "EUR":
            return "\(base) €"
        default:
            return "\(base) \(currency)"
        }
    }

    static func parseAPIDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    static func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }

    static func formatDayTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }

    static func daysUntilText(from value: String?, relativeTo reference: Date = Date()) -> String {
        guard let date = parseAPIDate(value) else { return "Дата неизвестна" }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: reference)
        let target = calendar.startOfDay(for: date)
        let diff = calendar.dateComponents([.day], from: start, to: target).day ?? 0

        if diff <= 0 { return diff == 0 ? "Сегодня" : "Просрочено" }
        if diff == 1 { return "Через 1 дн." }
        return "Через \(diff) дн."
    }

    static func firstLetter(from value: String?) -> String {
        guard let value, let first = value.trimmingCharacters(in: .whitespacesAndNewlines).first else {
            return "?"
        }
        return String(first).uppercased()
    }

    static func billingMultiplier(for billingPeriod: String, months: Int) -> Double {
        switch billingPeriod.lowercased() {
        case "monthly":
            return Double(months)
        case "weekly":
            return Double(months) * 4.345
        case "yearly":
            return Double(months) / 12.0
        case "half_year":
            return Double(months) / 6.0
        default:
            return billingPeriod.lowercased().contains("year") ? Double(months) / 12.0 : Double(months)
        }
    }
}
