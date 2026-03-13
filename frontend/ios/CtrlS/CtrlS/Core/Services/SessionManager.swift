import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published private(set) var accessToken: String? {
        didSet {
            UserDefaults.standard.set(accessToken, forKey: "accessToken")
        }
    }

    var isAuthenticated: Bool {
        accessToken != nil && !(accessToken ?? "").isEmpty
    }

    private init() {
        accessToken = UserDefaults.standard.string(forKey: "accessToken")
    }

    func setToken(_ token: String) {
        accessToken = token
    }

    func logout() {
        accessToken = nil
    }
}
