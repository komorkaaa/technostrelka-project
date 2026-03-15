import Foundation

final class MockAPIService: APIService {
    static let shared = MockAPIService()

    func fetchHomeSummary() async throws -> HomeSummary {
        HomeSummary(
            totalMonthly: "6 045 ₽",
            changeText: "+12% от прошлого месяца",
            activeCount: "7",
            nextPayment: "-1 дн.",
            savings: "1 240 ₽",
            upcomingAlert: "Через 3 дня будет списано 3 499 ₽ за Adobe Creative Cloud"
        )
    }

    func fetchUpcomingPayments(days: Int) async throws -> [PaymentRowModel] {
        [
            PaymentRowModel(title: "Notion", subtitle: "Через 1 дн.", amount: "8 $", colorName: "black"),
            PaymentRowModel(title: "Spotify", subtitle: "Через 2 дн.", amount: "169 ₽", colorName: "green"),
            PaymentRowModel(title: "Okko", subtitle: "Через 5 дн.", amount: "599 ₽", colorName: "orange"),
            PaymentRowModel(title: "Яндекс Плюс", subtitle: "Через 7 дн.", amount: "399 ₽", colorName: "red")
        ]
    }

    func fetchCategories() async throws -> [CategoryChipModel] {
        [
            CategoryChipModel(title: "Стриминг", count: "2"),
            CategoryChipModel(title: "Музыка", count: "3"),
            CategoryChipModel(title: "ПО", count: "4"),
            CategoryChipModel(title: "Облако", count: "5")
        ]
    }

    func fetchSubscriptions(query: String?, status: SubscriptionStatus?) async throws -> [Subscription] {
        let all: [Subscription] = [
            Subscription(
                id: 1,
                name: "Яндекс Плюс",
                category: "Стриминг",
                billingPeriod: "monthly",
                amount: 399,
                currency: "RUB",
                nextBillingDate: "2026-03-20",
                status: .active,
                formattedPrice: "399 ₽ / monthly",
                formattedDate: "20 мар."
            ),
            Subscription(
                id: 2,
                name: "Spotify",
                category: "Музыка",
                billingPeriod: "monthly",
                amount: 169,
                currency: "RUB",
                nextBillingDate: "2026-03-15",
                status: .active,
                formattedPrice: "169 ₽ / monthly",
                formattedDate: "15 мар."
            ),
            Subscription(
                id: 3,
                name: "Adobe Creative Cloud",
                category: "ПО",
                billingPeriod: "monthly",
                amount: 3499,
                currency: "RUB",
                nextBillingDate: "2026-03-25",
                status: .active,
                formattedPrice: "3 499 ₽ / monthly",
                formattedDate: "25 мар."
            ),
            Subscription(
                id: 4,
                name: "Okko",
                category: "Кино",
                billingPeriod: "monthly",
                amount: 599,
                currency: "RUB",
                nextBillingDate: "2026-03-18",
                status: .active,
                formattedPrice: "599 ₽ / monthly",
                formattedDate: "18 мар."
            ),
            Subscription(
                id: 5,
                name: "Notion",
                category: "Работа",
                billingPeriod: "monthly",
                amount: 8,
                currency: "USD",
                nextBillingDate: "2026-03-12",
                status: .active,
                formattedPrice: "8 $ / monthly",
                formattedDate: "12 мар."
            ),
            Subscription(
                id: 6,
                name: "Readymag",
                category: "Дизайн",
                billingPeriod: "monthly",
                amount: 16,
                currency: "USD",
                nextBillingDate: "2026-03-28",
                status: .paused,
                formattedPrice: "16 $ / monthly",
                formattedDate: "28 мар."
            )
        ]

        let filteredByStatus = status.map { st in
            all.filter { $0.status == st }
        } ?? all

        if let query, !query.isEmpty {
            return filteredByStatus.filter { $0.title.localizedCaseInsensitiveContains(query) }
        }

        return filteredByStatus
    }

    func fetchNotifications() async throws -> [NotificationItem] {
        [
            NotificationItem(
                title: "Списание через 3 дня",
                message: "Adobe Creative Cloud — 3 499 ₽",
                time: "Сегодня"
            ),
            NotificationItem(
                title: "Новый платёж добавлен",
                message: "Notion — 8 $",
                time: "Вчера"
            ),
            NotificationItem(
                title: "Экономия за месяц",
                message: "Вы сэкономили 1 240 ₽",
                time: "2 дня назад"
            )
        ]
    }

    func fetchAnalyticsOverview(period: AnalyticsPeriod, category: String?) async throws -> AnalyticsOverview {
        let metrics = [
            AnalyticsMetric(title: "Средний расход", value: "6 286 ₽", accentName: "purple", icon: "dollarsign.circle"),
            AnalyticsMetric(title: "Тренд", value: "-4.4%", accentName: "green", icon: "arrow.down.right"),
            AnalyticsMetric(title: "Экономия", value: "1 240 ₽", accentName: "green", icon: "leaf"),
            AnalyticsMetric(title: "Эффективность", value: "87%", accentName: "blue", icon: "percent")
        ]

        let chartPoints = [
            AnalyticsChartPoint(label: "Стриминг", value: 4850),
            AnalyticsChartPoint(label: "Музыка", value: 5600),
            AnalyticsChartPoint(label: "ПО", value: 5150),
            AnalyticsChartPoint(label: "Образование", value: 6200),
            AnalyticsChartPoint(label: "Облако", value: 7150)
        ]

        let categories = [
            AnalyticsCategoryBreakdown(title: "ПО", value: 4579, formattedValue: "4 579 ₽", colorName: "orange"),
            AnalyticsCategoryBreakdown(title: "Стриминг", value: 998, formattedValue: "998 ₽", colorName: "purple"),
            AnalyticsCategoryBreakdown(title: "Музыка", value: 169, formattedValue: "169 ₽", colorName: "pink"),
            AnalyticsCategoryBreakdown(title: "Образование", value: 299, formattedValue: "299 ₽", colorName: "green")
        ]

        return AnalyticsOverview(
            metrics: metrics,
            chartPoints: chartPoints,
            chartMin: "4 850 ₽",
            chartMax: "7 150 ₽",
            categories: categories
        )
    }

    func fetchAnalyticsTotals() async throws -> AnalyticsTotals {
        AnalyticsTotals(month: 6286, halfYear: 37716, year: 75432)
    }

    func fetchForecast() async throws -> ForecastSummary {
        ForecastSummary(month: "6 045 ₽", halfYear: "36 270 ₽", year: "72 540 ₽")
    }

    func fetchProfile() async throws -> UserProfile {
        UserProfile(id: 1, email: "petr@example.com", phone: "+7 900 000 00 00")
    }

    func importSubscriptionsFromEmail(_ request: EmailImportRequest) async throws -> EmailImportResult {
        let parsed = [
            EmailParsedSubscription(
                service: "Netflix",
                amount: "399.00",
                currency: "RUB",
                sender: "billing@netflix.com",
                subject: "Your Netflix receipt"
            ),
            EmailParsedSubscription(
                service: "Spotify",
                amount: "549.00",
                currency: "RUB",
                sender: "billing@spotify.com",
                subject: "Spotify Premium payment"
            )
        ]
        return EmailImportResult(parsed: parsed, created: 2)
    }

    func updateProfile(_ payload: ProfileUpdatePayload) async throws -> UserProfile {
        UserProfile(id: 1, email: payload.email ?? "petr@example.com", phone: payload.phone)
    }

    func changePassword(_ payload: PasswordChangePayload) async throws {}

    func createSubscription(_ payload: SubscriptionPayload) async throws -> Subscription {
        Subscription(
            id: 999,
            name: payload.name,
            category: payload.category,
            billingPeriod: payload.billingPeriod,
            amount: payload.amount,
            currency: payload.currency,
            nextBillingDate: nil,
            status: .active,
            formattedPrice: "\(payload.amount) \(payload.currency) / \(payload.billingPeriod)",
            formattedDate: "—"
        )
    }

    func updateSubscription(id: Int, payload: SubscriptionPayload) async throws -> Subscription {
        Subscription(
            id: id,
            name: payload.name,
            category: payload.category,
            billingPeriod: payload.billingPeriod,
            amount: payload.amount,
            currency: payload.currency,
            nextBillingDate: nil,
            status: .active,
            formattedPrice: "\(payload.amount) \(payload.currency) / \(payload.billingPeriod)",
            formattedDate: "—"
        )
    }

    func deleteSubscription(id: Int) async throws {}
}
