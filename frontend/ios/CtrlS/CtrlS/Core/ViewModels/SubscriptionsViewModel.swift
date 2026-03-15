import Foundation
import Combine

@MainActor
final class SubscriptionsViewModel: ObservableObject {
    @Published var allSubscriptions: [Subscription] = []
    @Published var subscriptions: [Subscription] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load(query: String?, status: SubscriptionStatus?) async {
        do {
            isLoading = true
            errorMessage = nil
            allSubscriptions = try await service.fetchSubscriptions(query: nil, status: nil)
            applyFilters(query: query, status: status, sort: .nextDate)
        } catch let apiError as APIError {
            errorMessage = apiError.message
            allSubscriptions = []
            subscriptions = []
        } catch {
            errorMessage = error.localizedDescription
            allSubscriptions = []
            subscriptions = []
        }
        isLoading = false
    }

    func create(payload: SubscriptionPayload, query: String?, status: SubscriptionStatus?) async throws {
        do {
            isLoading = true
            errorMessage = nil
            _ = try await service.createSubscription(payload)
            allSubscriptions = try await service.fetchSubscriptions(query: nil, status: nil)
            applyFilters(query: query, status: status, sort: .nextDate)
        } catch let apiError as APIError {
            errorMessage = apiError.message
            isLoading = false
            throw apiError
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            throw error
        }
        isLoading = false
    }

    func update(id: Int, payload: SubscriptionPayload, query: String?, status: SubscriptionStatus?) async throws {
        do {
            isLoading = true
            errorMessage = nil
            _ = try await service.updateSubscription(id: id, payload: payload)
            allSubscriptions = try await service.fetchSubscriptions(query: nil, status: nil)
            applyFilters(query: query, status: status, sort: .nextDate)
        } catch let apiError as APIError {
            errorMessage = apiError.message
            isLoading = false
            throw apiError
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            throw error
        }
        isLoading = false
    }

    func delete(id: Int, query: String?, status: SubscriptionStatus?) async throws {
        do {
            isLoading = true
            errorMessage = nil
            try await service.deleteSubscription(id: id)
            allSubscriptions = try await service.fetchSubscriptions(query: nil, status: nil)
            applyFilters(query: query, status: status, sort: .nextDate)
        } catch let apiError as APIError {
            errorMessage = apiError.message
            isLoading = false
            throw apiError
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            throw error
        }
        isLoading = false
    }

    enum SortOption: String, CaseIterable {
        case nextDate = "По дате"
        case amountDesc = "По сумме"
        case name = "По названию"
    }

    func applyFilters(query: String?, status: SubscriptionStatus?, sort: SortOption) {
        var filtered = allSubscriptions

        if let status {
            filtered = filtered.filter { $0.status == status }
        }

        if let query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(query) }
        }

        switch sort {
        case .nextDate:
            filtered = filtered.sorted {
                let left = Self.parseDate($0.nextBillingDate) ?? .distantFuture
                let right = Self.parseDate($1.nextBillingDate) ?? .distantFuture
                return left < right
            }
        case .amountDesc:
            filtered = filtered.sorted { $0.amount > $1.amount }
        case .name:
            filtered = filtered.sorted { $0.title < $1.title }
        }

        subscriptions = filtered
    }

    static func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}
