import Foundation
import Combine

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var overview: AnalyticsOverview?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var period: AnalyticsPeriod = .month
    @Published var selectedCategory: String? = nil

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load(period: AnalyticsPeriod? = nil, category: String? = nil) async {
        do {
            isLoading = true
            errorMessage = nil
            if let period { self.period = period }
            if category != nil { self.selectedCategory = category }
            overview = try await service.fetchAnalyticsOverview(
                period: self.period,
                category: self.selectedCategory
            )
        } catch let apiError as APIError {
            errorMessage = apiError.message
            overview = nil
        } catch {
            errorMessage = error.localizedDescription
            overview = nil
        }
        isLoading = false
    }

    var availableCategories: [String] {
        overview?.categories.map { $0.title } ?? []
    }
}
