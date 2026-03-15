import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var summary: HomeSummary?
    @Published var upcomingPayments: [PaymentRowModel] = []
    @Published var categories: [CategoryChipModel] = []
    @Published var recentSubscriptions: [Subscription] = []
    @Published var forecast: ForecastSummary?
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load() async {
        do {
            isLoading = true
            errorMessage = nil
            async let summaryValue = service.fetchHomeSummary()
            async let paymentsValue = service.fetchUpcomingPayments(days: 30)
            async let categoriesValue = service.fetchCategories()
            async let forecastValue = service.fetchForecast()
            async let subscriptionsValue = service.fetchSubscriptions(query: nil, status: nil)

            summary = try await summaryValue
            upcomingPayments = try await paymentsValue
            categories = try await categoriesValue
            forecast = try await forecastValue
            let subscriptions = try await subscriptionsValue
            recentSubscriptions = subscriptions
                .sorted {
                    let left = SubscriptionsViewModel.parseDate($0.nextBillingDate) ?? .distantFuture
                    let right = SubscriptionsViewModel.parseDate($1.nextBillingDate) ?? .distantFuture
                    return left < right
                }
                .prefix(3)
                .map { $0 }
        } catch let apiError as APIError {
            errorMessage = apiError.message
            summary = nil
            upcomingPayments = []
            categories = []
            recentSubscriptions = []
            forecast = nil
        } catch {
            errorMessage = error.localizedDescription
            summary = nil
            upcomingPayments = []
            categories = []
            recentSubscriptions = []
            forecast = nil
        }
        isLoading = false
    }
}
