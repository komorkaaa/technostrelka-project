import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var summary: HomeSummary?
    @Published var upcomingPayments: [PaymentRowModel] = []
    @Published var categories: [CategoryChipModel] = []
    @Published var errorMessage: String?

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load() async {
        do {
            errorMessage = nil
            summary = try await service.fetchHomeSummary()
            upcomingPayments = try await service.fetchUpcomingPayments()
            categories = try await service.fetchCategories()
        } catch let apiError as APIError {
            errorMessage = apiError.message
            summary = nil
            upcomingPayments = []
            categories = []
        } catch {
            errorMessage = error.localizedDescription
            summary = nil
            upcomingPayments = []
            categories = []
        }
    }
}
