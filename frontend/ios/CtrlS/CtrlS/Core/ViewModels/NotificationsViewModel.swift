import Foundation
import Combine

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load() async {
        do {
            notifications = try await service.fetchNotifications()
        } catch {
            notifications = []
        }
    }
}
