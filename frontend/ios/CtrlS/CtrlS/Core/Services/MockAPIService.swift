import Foundation

final class MockAPIService: APIService {
    static let shared = MockAPIService()

    func fetchHomeSummary() async throws -> HomeSummary {
        HomeSummary(
            totalMonthly: "6 045 ₽",
            changeText: "+12% от прошлого месяца",
            activeCount: "7",
            nextPayment: "-1 дн.",
            savings: "1 240 ₽",
            upcomingAlert: "Через 3 дня будет списано 3 499 ₽ за Adobe Creative Cloud"
        )
    }

    func fetchUpcomingPayments() async throws -> [PaymentRowModel] {
        [
            PaymentRowModel(title: "Notion", subtitle: "Через 1 дн.", amount: "8 $", colorName: "black"),
            PaymentRowModel(title: "Spotify", subtitle: "Через 2 дн.", amount: "169 ₽", colorName: "green"),
            PaymentRowModel(title: "Okko", subtitle: "Через 5 дн.", amount: "599 ₽", colorName: "orange"),
            PaymentRowModel(title: "Яндекс Плюс", subtitle: "Через 7 дн.", amount: "399 ₽", colorName: "red")
        ]
    }

    func fetchCategories() async throws -> [CategoryChipModel] {
        [
            CategoryChipModel(title: "Стриминг", count: "2"),
            CategoryChipModel(title: "Музыка", count: "3"),
            CategoryChipModel(title: "ПО", count: "4"),
            CategoryChipModel(title: "Облако", count: "5")
        ]
    }

    func fetchSubscriptions(query: String?, status: SubscriptionStatus?) async throws -> [Subscription] {
        let all: [Subscription] = [
            Subscription(
                title: "Яндекс Плюс",
                subtitle: "Подписка на Яндекс Плюс с доступом к...",
                price: "399 ₽ / в месяц",
                status: .active,
                date: "20 мар."
            ),
            Subscription(
                title: "Spotify",
                subtitle: "Премиум подписка на музыкальный сервис",
                price: "169 ₽ / в месяц",
                status: .active,
                date: "15 мар."
            ),
            Subscription(
                title: "Adobe Creative Cloud",
                subtitle: "Полный пакет приложений Adobe",
                price: "3 499 ₽ / в месяц",
                status: .active,
                date: "25 мар."
            ),
            Subscription(
                title: "Okko",
                subtitle: "Онлайн‑кинотеатр",
                price: "599 ₽ / в месяц",
                status: .active,
                date: "18 мар."
            ),
            Subscription(
                title: "Notion",
                subtitle: "Сервис для организации работы",
                price: "8 $ / в месяц",
                status: .active,
                date: "12 мар."
            ),
            Subscription(
                title: "Readymag",
                subtitle: "Конструктор сайтов",
                price: "16 $ / в месяц",
                status: .paused,
                date: "28 мар."
            )
        ]

        let filteredByStatus = status.map { st in
            all.filter { $0.status == st }
        } ?? all

        if let query, !query.isEmpty {
            return filteredByStatus.filter { $0.title.localizedCaseInsensitiveContains(query) }
        }

        return filteredByStatus
    }

    func fetchNotifications() async throws -> [NotificationItem] {
        [
            NotificationItem(
                title: "Списание через 3 дня",
                message: "Adobe Creative Cloud — 3 499 ₽",
                time: "Сегодня"
            ),
            NotificationItem(
                title: "Новый платёж добавлен",
                message: "Notion — 8 $",
                time: "Вчера"
            ),
            NotificationItem(
                title: "Экономия за месяц",
                message: "Вы сэкономили 1 240 ₽",
                time: "2 дня назад"
            )
        ]
    }
}
