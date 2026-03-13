import Foundation
import Combine

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var overview: AnalyticsOverview?
    @Published var errorMessage: String?

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load(period: AnalyticsPeriod = .month, category: String? = nil) async {
        do {
            errorMessage = nil
            overview = try await service.fetchAnalyticsOverview(period: period, category: category)
        } catch let apiError as APIError {
            errorMessage = apiError.message
            overview = nil
        } catch {
            errorMessage = error.localizedDescription
            overview = nil
        }
    }
}
