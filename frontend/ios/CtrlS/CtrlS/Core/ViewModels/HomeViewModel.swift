import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var allSubscriptions: [Subscription] = []
    @Published var summary: HomeSummary?
    @Published var upcomingPayments: [PaymentRowModel] = []
    @Published var categories: [CategoryChipModel] = []
    @Published var recentSubscriptions: [Subscription] = []
    @Published var forecast: ForecastSummary?
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load() async {
        do {
            isLoading = true
            errorMessage = nil
            let subscriptions = try await service.fetchSubscriptions(query: nil, status: nil)
            allSubscriptions = subscriptions
            summary = makeSummary(from: subscriptions)
            upcomingPayments = makeUpcomingPayments(from: subscriptions)
            categories = makeCategories(from: subscriptions)
            recentSubscriptions = subscriptions
                .sorted {
                    let left = SubscriptionsViewModel.parseDate($0.nextBillingDate) ?? .distantFuture
                    let right = SubscriptionsViewModel.parseDate($1.nextBillingDate) ?? .distantFuture
                    return left < right
                }
                .prefix(3)
                .map { $0 }
            forecast = nil
        } catch let apiError as APIError {
            errorMessage = apiError.message
            allSubscriptions = []
            summary = nil
            upcomingPayments = []
            categories = []
            recentSubscriptions = []
            forecast = nil
        } catch {
            errorMessage = error.localizedDescription
            allSubscriptions = []
            summary = nil
            upcomingPayments = []
            categories = []
            recentSubscriptions = []
            forecast = nil
        }
        isLoading = false
    }

    func projectedTotal(months: Int) -> String {
        let total = allSubscriptions.reduce(0.0) { partial, subscription in
            partial + subscription.amount * AppDisplay.billingMultiplier(for: subscription.billingPeriod, months: months)
        }
        return AppDisplay.formatAmount(total, currency: "RUB")
    }

    func visibleUpcomingPayments(showAll: Bool) -> [PaymentRowModel] {
        showAll ? upcomingPayments : Array(upcomingPayments.prefix(3))
    }

    private func makeSummary(from subscriptions: [Subscription]) -> HomeSummary {
        let today = Calendar.current.startOfDay(for: Date())
        let upcoming = subscriptions
            .compactMap { subscription -> (Subscription, Date)? in
                guard let date = AppDisplay.parseAPIDate(subscription.nextBillingDate) else { return nil }
                return (subscription, date)
            }
            .filter { $0.1 >= today }
            .sorted { $0.1 < $1.1 }

        let activeCount = "\(upcoming.count)"
        let nearestDaysText = upcoming.first.map {
            let diff = Calendar.current.dateComponents([.day], from: today, to: $0.1).day ?? 0
            return diff == 0 ? "Сегодня" : "Через \(diff) дн."
        } ?? "—"

        let upcomingAlert = upcoming.first.map {
            let diff = Calendar.current.dateComponents([.day], from: today, to: $0.1).day ?? 0
            let when = diff == 0 ? "Сегодня" : "Через \(diff) дн."
            return "\(when) будет списано \(AppDisplay.formatAmount($0.0.amount, currency: $0.0.currency)) за \($0.0.title)"
        } ?? "Нет ближайших списаний"

        return HomeSummary(
            totalMonthly: projectedTotal(months: 1),
            changeText: "",
            activeCount: activeCount,
            nextPayment: nearestDaysText,
            savings: "—",
            upcomingAlert: upcomingAlert
        )
    }

    private func makeUpcomingPayments(from subscriptions: [Subscription]) -> [PaymentRowModel] {
        let today = Calendar.current.startOfDay(for: Date())
        return subscriptions
            .compactMap { subscription -> (Subscription, Date)? in
                guard let date = AppDisplay.parseAPIDate(subscription.nextBillingDate) else { return nil }
                return (subscription, date)
            }
            .filter { $0.1 >= today }
            .sorted { $0.1 < $1.1 }
            .map { subscription, date in
                let diff = Calendar.current.dateComponents([.day], from: today, to: date).day ?? 0
                let subtitle = diff == 0 ? "Сегодня" : "Через \(diff) дн."
                return PaymentRowModel(
                    title: subscription.title,
                    subtitle: subtitle,
                    amount: AppDisplay.formatAmount(subscription.amount, currency: subscription.currency),
                    colorName: "purple"
                )
            }
    }

    private func makeCategories(from subscriptions: [Subscription]) -> [CategoryChipModel] {
        let grouped = Dictionary(grouping: subscriptions) { subscription in
            let raw = subscription.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return raw.isEmpty ? "Без категории" : raw
        }

        return grouped
            .map { CategoryChipModel(title: $0.key, count: "\($0.value.count)") }
            .sorted {
                let left = Int($0.count) ?? 0
                let right = Int($1.count) ?? 0
                if left == right { return $0.title < $1.title }
                return left > right
            }
            .prefix(4)
            .map { $0 }
    }
}
