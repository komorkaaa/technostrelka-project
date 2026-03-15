import Foundation
import Combine

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var errorMessage: String?

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load() async {
        do {
            errorMessage = nil
            notifications = try await service.fetchNotifications()
        } catch let apiError as APIError {
            errorMessage = apiError.message
            notifications = []
        } catch {
            errorMessage = error.localizedDescription
            notifications = []
        }
    }
}
