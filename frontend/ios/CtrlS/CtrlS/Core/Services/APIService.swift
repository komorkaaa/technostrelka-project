import Foundation

protocol APIService {
    func fetchHomeSummary() async throws -> HomeSummary
    func fetchUpcomingPayments(days: Int) async throws -> [PaymentRowModel]
    func fetchCategories() async throws -> [CategoryChipModel]
    func fetchSubscriptions(query: String?, status: SubscriptionStatus?) async throws -> [Subscription]
    func createSubscription(_ payload: SubscriptionPayload) async throws -> Subscription
    func updateSubscription(id: Int, payload: SubscriptionPayload) async throws -> Subscription
    func deleteSubscription(id: Int) async throws
    func fetchNotifications() async throws -> [NotificationItem]
    func fetchAnalyticsOverview(period: AnalyticsPeriod, category: String?) async throws -> AnalyticsOverview
    func fetchAnalyticsTotals() async throws -> AnalyticsTotals
    func fetchForecast() async throws -> ForecastSummary
    func fetchProfile() async throws -> UserProfile
}
