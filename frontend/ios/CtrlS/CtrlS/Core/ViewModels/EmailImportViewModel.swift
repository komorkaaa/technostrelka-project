import Foundation
import Combine

@MainActor
final class EmailImportViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var imapServer: String = "imap.gmail.com"
    @Published var mailbox: String = "INBOX"
    @Published var limit: Int = 20
    @Published var useSample: Bool = false
    @Published var consentToUsePassword: Bool = false

    @Published var result: EmailImportResult?
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func submit() async {
        errorMessage = nil
        result = nil

        if !useSample {
            if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "Введите email для импорта."
                return
            }
            if password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "Введите пароль приложения для почты."
                return
            }
            if !consentToUsePassword {
                errorMessage = "Подтвердите согласие на использование пароля."
                return
            }
        }

        isLoading = true
        let request = EmailImportRequest(
            email: useSample ? nil : email,
            password: useSample ? nil : password,
            imapServer: imapServer,
            mailbox: mailbox,
            limit: limit,
            useSample: useSample,
            consentToUsePassword: consentToUsePassword
        )

        do {
            result = try await service.importSubscriptionsFromEmail(request)
        } catch let apiError as APIError {
            errorMessage = apiError.message
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
