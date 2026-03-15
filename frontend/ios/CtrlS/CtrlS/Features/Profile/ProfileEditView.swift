import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var phone: String
    @State private var errorMessage: String?
    @State private var isSaving = false

    private let onSave: (String?, String?) async -> Bool

    init(email: String?, phone: String?, onSave: @escaping (String?, String?) async -> Bool) {
        _email = State(initialValue: email ?? "")
        _phone = State(initialValue: phone ?? "")
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Контакты") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    TextField("Телефон", text: $phone)
                        .keyboardType(.phonePad)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Личная информация")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Сохранение..." : "Сохранить") {
                        Task { await submit() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
}

private extension ProfileEditView {
    func submit() async {
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            errorMessage = "Введите email."
            return
        }

        isSaving = true
        let ok = await onSave(trimmedEmail, trimmedPhone.isEmpty ? nil : trimmedPhone)
        isSaving = false
        if ok {
            dismiss()
        } else {
            errorMessage = errorMessage ?? "Не удалось сохранить."
        }
    }
}

#Preview {
    ProfileEditView(email: "demo@example.com", phone: "+7 900 000 00 00") { _, _ in true }
}
