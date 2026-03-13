import Foundation
import Combine

@MainActor
final class SubscriptionsViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load(query: String?, status: SubscriptionStatus?) async {
        do {
            subscriptions = try await service.fetchSubscriptions(query: query, status: status)
        } catch {
            subscriptions = []
        }
    }
}
