import Foundation

struct HomeSummary {
    let totalMonthly: String
    let changeText: String
    let activeCount: String
    let nextPayment: String
    let savings: String
    let upcomingAlert: String
}

struct PaymentRowModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: String
    let colorName: String
}

struct CategoryChipModel: Identifiable {
    let id = UUID()
    let title: String
    let count: String
}

enum SubscriptionStatus: String {
    case active = "Активна"
    case paused = "На паузе"
}

struct Subscription: Identifiable {
    let id: Int
    let name: String
    let category: String?
    let billingPeriod: String
    let amount: Double
    let currency: String
    let nextBillingDate: String?
    let status: SubscriptionStatus
    let formattedPrice: String
    let formattedDate: String

    var title: String { name }
    var subtitle: String { category ?? billingPeriod }
    var price: String { formattedPrice }
    var date: String { formattedDate }
}

struct NotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let time: String
}

enum AnalyticsPeriod: String {
    case month
    case halfYear = "half_year"
    case year
}

struct AnalyticsMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let accentName: String
    let icon: String
}

struct AnalyticsChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct AnalyticsCategoryBreakdown: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
    let formattedValue: String
    let colorName: String
}

struct AnalyticsOverview {
    let metrics: [AnalyticsMetric]
    let chartPoints: [AnalyticsChartPoint]
    let chartMin: String
    let chartMax: String
    let categories: [AnalyticsCategoryBreakdown]
}

struct AnalyticsTotals {
    let month: Double
    let halfYear: Double
    let year: Double
}

struct ForecastSummary {
    let month: String
    let halfYear: String
    let year: String
}

struct UserProfile {
    let id: Int
    let email: String
    let phone: String?
}

struct SubscriptionPayload {
    let name: String
    let amount: Double
    let currency: String
    let billingPeriod: String
    let category: String?
    let nextBillingDate: Date?
}
