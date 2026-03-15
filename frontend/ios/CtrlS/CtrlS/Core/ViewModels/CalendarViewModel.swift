import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var forecast: ForecastSummary?
    @Published var upcomingPayments: [PaymentRowModel] = []
    @Published var subscriptions: [Subscription] = []
    @Published var monthOffset: Int = 0
    @Published var selectedDate: Date = Date()
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
            async let subscriptionsValue = service.fetchSubscriptions(query: nil, status: nil)
            forecast = try await forecastValue
            upcomingPayments = try await paymentsValue
            subscriptions = try await subscriptionsValue
        } catch let apiError as APIError {
            errorMessage = apiError.message
            forecast = nil
            upcomingPayments = []
            subscriptions = []
        } catch {
            errorMessage = error.localizedDescription
            forecast = nil
            upcomingPayments = []
            subscriptions = []
        }
    }

    func setMonthOffset(_ offset: Int) {
        monthOffset = offset
        if let newDate = Calendar.current.date(byAdding: .month, value: offset, to: Date()) {
            selectedDate = newDate
        }
    }

    func currentMonthDate() -> Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    func payments(on date: Date) -> [Subscription] {
        let calendar = Calendar.current
        return subscriptions.filter { subscription in
            guard let dateString = subscription.nextBillingDate,
                  let billingDate = Self.parseDate(dateString) else { return false }
            return calendar.isDate(billingDate, inSameDayAs: date)
        }
    }

    func payments(in monthDate: Date) -> [Subscription] {
        let calendar = Calendar.current
        return subscriptions.filter { subscription in
            guard let dateString = subscription.nextBillingDate,
                  let billingDate = Self.parseDate(dateString) else { return false }
            return calendar.isDate(billingDate, equalTo: monthDate, toGranularity: .month)
        }
    }

    func totalAmount(in monthDate: Date) -> Double {
        payments(in: monthDate).reduce(0) { $0 + $1.amount }
    }

    func count(in monthDate: Date) -> Int {
        payments(in: monthDate).count
    }

    func daysForMonth() -> [CalendarDay] {
        let calendar = Calendar.current
        let monthDate = currentMonthDate()
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else { return [] }

        let startOfMonth = monthInterval.start
        let range = calendar.range(of: .day, in: .month, for: monthDate) ?? 1..<1
        let weekday = calendar.component(.weekday, from: startOfMonth)
        let leading = (weekday + 5) % 7 // Monday-based

        var days: [CalendarDay] = []
        if leading > 0 {
            for offset in stride(from: leading, to: 0, by: -1) {
                if let date = calendar.date(byAdding: .day, value: -offset, to: startOfMonth) {
                    days.append(CalendarDay(date: date, isInMonth: false, paymentsCount: payments(on: date).count))
                }
            }
        }

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(CalendarDay(date: date, isInMonth: true, paymentsCount: payments(on: date).count))
            }
        }

        while days.count % 7 != 0 {
            if let last = days.last?.date,
               let date = calendar.date(byAdding: .day, value: 1, to: last) {
                days.append(CalendarDay(date: date, isInMonth: false, paymentsCount: payments(on: date).count))
            } else {
                break
            }
        }

        return days
    }

    static func parseDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let isInMonth: Bool
    let paymentsCount: Int
}
