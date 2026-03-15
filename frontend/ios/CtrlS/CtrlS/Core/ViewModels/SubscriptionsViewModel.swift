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

    func create(payload: SubscriptionPayload, query: String?, status: SubscriptionStatus?) async throws {
        do {
            errorMessage = nil
            _ = try await service.createSubscription(payload)
            subscriptions = try await service.fetchSubscriptions(query: query, status: status)
        } catch let apiError as APIError {
            errorMessage = apiError.message
            throw apiError
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func update(id: Int, payload: SubscriptionPayload, query: String?, status: SubscriptionStatus?) async throws {
        do {
            errorMessage = nil
            _ = try await service.updateSubscription(id: id, payload: payload)
            subscriptions = try await service.fetchSubscriptions(query: query, status: status)
        } catch let apiError as APIError {
            errorMessage = apiError.message
            throw apiError
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func delete(id: Int, query: String?, status: SubscriptionStatus?) async throws {
        do {
            errorMessage = nil
            try await service.deleteSubscription(id: id)
            subscriptions = try await service.fetchSubscriptions(query: query, status: status)
        } catch let apiError as APIError {
            errorMessage = apiError.message
            throw apiError
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
