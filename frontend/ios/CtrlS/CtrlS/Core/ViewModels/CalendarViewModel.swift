import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var forecast: ForecastSummary?
    @Published var upcomingPayments: [PaymentRowModel] = []
    @Published var errorMessage: String?

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load() async {
        do {
            errorMessage = nil
            async let forecastValue = service.fetchForecast()
            async let paymentsValue = service.fetchUpcomingPayments(days: 7)
            forecast = try await forecastValue
            upcomingPayments = try await paymentsValue
        } catch let apiError as APIError {
            errorMessage = apiError.message
            forecast = nil
            upcomingPayments = []
        } catch {
            errorMessage = error.localizedDescription
            forecast = nil
            upcomingPayments = []
        }
    }
}
