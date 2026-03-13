import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var phone = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService()

    func login() async {
        if !validate() { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let token = try await authService.login(email: email, password: password)
            SessionManager.shared.setToken(token.access_token)
        } catch let apiError as APIError {
            errorMessage = apiError.message
        } catch let urlError as URLError where urlError.code == .appTransportSecurityRequiresSecureConnection {
            errorMessage = "ATS блокирует HTTP. Нужна настройка App Transport Security."
        } catch {
            errorMessage = "Не удалось войти. Проверьте данные."
        }
    }

    func register() async {
        if !validate() { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await authService.register(email: email, password: password, phone: phone.isEmpty ? nil : phone)
            let token = try await authService.login(email: email, password: password)
            SessionManager.shared.setToken(token.access_token)
        } catch let apiError as APIError {
            errorMessage = apiError.message
        } catch let urlError as URLError where urlError.code == .appTransportSecurityRequiresSecureConnection {
            errorMessage = "ATS блокирует HTTP. Нужна настройка App Transport Security."
        } catch {
            errorMessage = "Не удалось зарегистрироваться."
        }
    }

    private func validate() -> Bool {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Введите email."
            return false
        }
        if password.count < 6 {
            errorMessage = "Пароль минимум 6 символов."
            return false
        }
        return true
    }
}
