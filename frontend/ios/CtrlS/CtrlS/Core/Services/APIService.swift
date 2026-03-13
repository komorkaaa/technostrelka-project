import Foundation

protocol APIService {
    func fetchHomeSummary() async throws -> HomeSummary
    func fetchUpcomingPayments() async throws -> [PaymentRowModel]
    func fetchCategories() async throws -> [CategoryChipModel]
    func fetchSubscriptions(query: String?, status: SubscriptionStatus?) async throws -> [Subscription]
    func fetchNotifications() async throws -> [NotificationItem]
}
