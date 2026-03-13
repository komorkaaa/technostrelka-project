import Foundation
import Combine

@MainActor
final class SubscriptionsViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var errorMessage: String?

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load(query: String?, status: SubscriptionStatus?) async {
        do {
            errorMessage = nil
            subscriptions = try await service.fetchSubscriptions(query: query, status: status)
        } catch let apiError as APIError {
            errorMessage = apiError.message
            subscriptions = []
        } catch {
            errorMessage = error.localizedDescription
            subscriptions = []
        }
    }
}
