import Foundation

struct HomeSummary {
    let totalMonthly: String
    let changeText: String
    let activeCount: String
    let nextPayment: String
    let savings: String
    let upcomingAlert: String
}

struct PaymentRowModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: String
    let colorName: String
}

struct CategoryChipModel: Identifiable {
    let id = UUID()
    let title: String
    let count: String
}

enum SubscriptionStatus: String {
    case active = "Активна"
    case paused = "На паузе"
}

struct Subscription: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let price: String
    let status: SubscriptionStatus
    let date: String
}

struct NotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let time: String
}
