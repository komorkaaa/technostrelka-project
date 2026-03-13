import Foundation

final class RealAPIService: APIService {
    static let shared = RealAPIService()

    private let client = APIClient(baseURL: AppConfig.baseURL, tokenProvider: { SessionManager.shared.accessToken })

    func fetchHomeSummary() async throws -> HomeSummary {
        async let analytics: AnalyticsResponseDTO = client.request("analytics")
        async let subscriptions: [SubscriptionDTO] = client.request("subscriptions")
        async let upcoming: UpcomingNotificationsResponseDTO = client.request("notifications/upcoming", query: ["days": "7"])

        let analyticsValue = try await analytics
        let subscriptionsValue = try await subscriptions
        let upcomingValue = try await upcoming

        let totalMonthly = formatAmount(analyticsValue.totals.month, currency: "RUB")
        let activeCount = "\(subscriptionsValue.count)"

        let nextPayment = upcomingValue.items.sorted(by: { $0.days_until < $1.days_until }).first
        let nextPaymentText = nextPayment.map { formatDaysUntil($0.days_until) } ?? "—"
        let upcomingAlert = nextPayment.map {
            "Через \(formatDaysUntilRaw($0.days_until)) будет списано \(formatAmount($0.amount, currency: $0.currency)) за \($0.name)"
        } ?? "Нет ближайших списаний"

        return HomeSummary(
            totalMonthly: totalMonthly,
            changeText: "",
            activeCount: activeCount,
            nextPayment: nextPaymentText,
            savings: "—",
            upcomingAlert: upcomingAlert
        )
    }

    func fetchUpcomingPayments() async throws -> [PaymentRowModel] {
        let response: UpcomingNotificationsResponseDTO = try await client.request("notifications/upcoming", query: ["days": "30"])
        return response.items.map {
            PaymentRowModel(
                title: $0.name,
                subtitle: "Через \(formatDaysUntilRaw($0.days_until))",
                amount: formatAmount($0.amount, currency: $0.currency),
                colorName: "purple"
            )
        }
    }

    func fetchCategories() async throws -> [CategoryChipModel] {
        let response: AnalyticsResponseDTO = try await client.request("analytics")
        return response.by_category.map { key, value in
            CategoryChipModel(title: key, count: formatAmountCompact(value))
        }
    }

    func fetchSubscriptions(query: String?, status: SubscriptionStatus?) async throws -> [Subscription] {
        let response: [SubscriptionDTO] = try await client.request("subscriptions")
        let mapped = response.map { dto in
            Subscription(
                title: dto.name,
                subtitle: dto.category ?? dto.billing_period,
                price: "\(formatAmount(dto.amount, currency: dto.currency)) / \(dto.billing_period)",
                status: .active,
                date: formatDate(dto.next_billing_date)
            )
        }

        let filtered = status.map { st in
            mapped.filter { $0.status == st }
        } ?? mapped

        if let query, !query.isEmpty {
            return filtered.filter { $0.title.localizedCaseInsensitiveContains(query) }
        }

        return filtered
    }

    func fetchNotifications() async throws -> [NotificationItem] {
        let response: UpcomingNotificationsResponseDTO = try await client.request("notifications/upcoming", query: ["days": "30"])
        return response.items.map {
            NotificationItem(
                title: "Списание через \(formatDaysUntilRaw($0.days_until))",
                message: "\($0.name) — \(formatAmount($0.amount, currency: $0.currency))",
                time: formatDate($0.next_billing_date)
            )
        }
    }

    func fetchAnalyticsOverview(period: AnalyticsPeriod, category: String?) async throws -> AnalyticsOverview {
        async let summary: AnalyticsResponseDTO = client.request("analytics")
        async let chart: AnalyticsChartResponseDTO = client.request(
            "analytics/chart",
            query: ["period": period.rawValue, "category": category]
        )

        let summaryValue = try await summary
        let chartValue = try await chart

        let totalMonth = summaryValue.totals.month.value
        let avgHalfYear = summaryValue.totals.half_year.value / 6.0
        let trendValue = percentChange(current: totalMonth, previous: avgHalfYear)

        let savingsValue: String = {
            guard avgHalfYear > 0 else { return "—" }
            let delta = avgHalfYear - totalMonth
            return delta > 0 ? formatAmount(delta, currency: "RUB") : "—"
        }()

        let categories = mapCategories(summaryValue.by_category)
        let topShare = categories.first.map { category in
            guard totalMonth > 0 else { return "—" }
            let ratio = max(0.0, 1.0 - (category.value / totalMonth))
            return "\(Int((ratio * 100).rounded()))%"
        } ?? "—"

        let metrics = [
            AnalyticsMetric(title: "Средний расход", value: formatAmount(summaryValue.totals.month, currency: "RUB"), accentName: "purple", icon: "dollarsign.circle"),
            AnalyticsMetric(title: "Тренд", value: trendValue, accentName: "green", icon: "arrow.down.right"),
            AnalyticsMetric(title: "Экономия", value: savingsValue, accentName: "green", icon: "leaf"),
            AnalyticsMetric(title: "Эффективность", value: topShare, accentName: "blue", icon: "percent")
        ]

        let chartPoints = chartValue.series.map { AnalyticsChartPoint(label: $0.label, value: $0.value.value) }
        let chartMinMax = minMax(from: chartValue.series)

        return AnalyticsOverview(
            metrics: metrics,
            chartPoints: chartPoints,
            chartMin: chartMinMax.min,
            chartMax: chartMinMax.max,
            categories: categories
        )
    }
}

private struct AnalyticsResponseDTO: Decodable {
    let by_category: [String: FlexibleDouble]
    let by_service: [String: FlexibleDouble]
    let totals: AnalyticsTotalsDTO
}

private struct AnalyticsChartResponseDTO: Decodable {
    let period: String
    let totals: AnalyticsTotalsDTO
    let series: [AnalyticsChartPointDTO]
    let category: String?
}

private struct AnalyticsChartPointDTO: Decodable {
    let label: String
    let value: FlexibleDouble
}

private struct AnalyticsTotalsDTO: Decodable {
    let month: FlexibleDouble
    let half_year: FlexibleDouble
    let year: FlexibleDouble
}

private struct UpcomingNotificationsResponseDTO: Decodable {
    let days: Int
    let items: [UpcomingNotificationItemDTO]
}

private struct UpcomingNotificationItemDTO: Decodable {
    let id: Int
    let name: String
    let amount: FlexibleDouble
    let currency: String
    let next_billing_date: String
    let days_until: Int
}

private struct SubscriptionDTO: Decodable {
    let id: Int
    let name: String
    let amount: FlexibleDouble
    let currency: String
    let billing_period: String
    let category: String?
    let next_billing_date: String?
}

private struct FlexibleDouble: Decodable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
            return
        }
        if let stringValue = try? container.decode(String.self),
           let doubleValue = Double(stringValue.replacingOccurrences(of: ",", with: ".")) {
            value = doubleValue
            return
        }
        throw DecodingError.typeMismatch(
            Double.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Double or String")
        )
    }
}

private func formatAmount(_ amount: FlexibleDouble, currency: String) -> String {
    let number = amount.value
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.locale = Locale(identifier: "ru_RU")
    let base = formatter.string(from: NSNumber(value: number)) ?? "\(number)"

    switch currency.uppercased() {
    case "RUB": return "\(base) ₽"
    case "USD": return "\(base) $"
    case "EUR": return "\(base) €"
    default: return "\(base) \(currency)"
    }
}

private func formatAmount(_ amount: Double, currency: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.locale = Locale(identifier: "ru_RU")
    let base = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"

    switch currency.uppercased() {
    case "RUB": return "\(base) ₽"
    case "USD": return "\(base) $"
    case "EUR": return "\(base) €"
    default: return "\(base) \(currency)"
    }
}

private func formatAmountCompact(_ amount: FlexibleDouble) -> String {
    let number = Int(amount.value)
    return "\(number)"
}

private func formatDaysUntil(_ value: Int) -> String {
    if value < 0 { return "-\(abs(value)) дн." }
    return "\(value) дн."
}

private func formatDaysUntilRaw(_ value: Int) -> String {
    if value < 0 { return "\(abs(value)) дн. (просрочено)" }
    return "\(value) дн."
}

private func formatDate(_ value: String?) -> String {
    guard let value else { return "—" }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ru_RU")
    formatter.dateFormat = "yyyy-MM-dd"
    guard let date = formatter.date(from: value) else { return value }
    let out = DateFormatter()
    out.locale = Locale(identifier: "ru_RU")
    out.dateFormat = "dd MMM"
    return out.string(from: date)
}

private func percentChange(current: Double, previous: Double) -> String {
    guard previous > 0 else { return "—" }
    let diff = ((current - previous) / previous) * 100
    let sign = diff > 0 ? "+" : ""
    return "\(sign)\(String(format: "%.1f", diff))%"
}

private func mapCategories(_ data: [String: FlexibleDouble]) -> [AnalyticsCategoryBreakdown] {
    let colors = ["purple", "pink", "orange", "green", "blue", "red", "gray"]
    let sorted = data
        .map { (title: $0.key, value: $0.value.value) }
        .sorted { $0.value > $1.value }

    return sorted.enumerated().map { index, item in
        AnalyticsCategoryBreakdown(
            title: item.title,
            value: item.value,
            formattedValue: formatAmount(item.value, currency: "RUB"),
            colorName: colors[index % colors.count]
        )
    }
}

private func minMax(from series: [AnalyticsChartPointDTO]) -> (min: String, max: String) {
    let values = series.map { $0.value.value }
    guard let minValue = values.min(), let maxValue = values.max() else {
        return (min: "—", max: "—")
    }
    return (min: formatAmount(minValue, currency: "RUB"), max: formatAmount(maxValue, currency: "RUB"))
}
