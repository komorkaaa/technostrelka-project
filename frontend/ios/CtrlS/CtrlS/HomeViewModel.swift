import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var summary: HomeSummary?
    @Published var upcomingPayments: [PaymentRowModel] = []
    @Published var categories: [CategoryChipModel] = []

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load() async {
        do {
            summary = try await service.fetchHomeSummary()
            upcomingPayments = try await service.fetchUpcomingPayments()
            categories = try await service.fetchCategories()
        } catch {
            summary = nil
            upcomingPayments = []
            categories = []
        }
    }
}
