import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    struct Stats {
        let subscriptions: String
        let monthly: String
        let savings: String
    }

    @Published var profile: UserProfile?
    @Published var stats: Stats?
    @Published var errorMessage: String?

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load() async {
        do {
            errorMessage = nil
            async let profileValue = service.fetchProfile()
            async let subscriptionsValue = service.fetchSubscriptions(query: nil, status: nil)
            async let totalsValue = service.fetchAnalyticsTotals()

            let profile = try await profileValue
            let subscriptions = try await subscriptionsValue
            let totals = try await totalsValue

            let monthlyText = formatAmount(totals.month)
            let avgHalfYear = totals.halfYear / 6.0
            let savingsValue = avgHalfYear - totals.month
            let savingsText = savingsValue > 0 ? formatAmount(savingsValue) : "—"

            self.profile = profile
            self.stats = Stats(
                subscriptions: "\(subscriptions.count)",
                monthly: monthlyText,
                savings: savingsText
            )
        } catch let apiError as APIError {
            errorMessage = apiError.message
            profile = nil
            stats = nil
        } catch {
            errorMessage = error.localizedDescription
            profile = nil
            stats = nil
        }
    }

    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "ru_RU")
        let base = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(base) ₽"
    }
}
