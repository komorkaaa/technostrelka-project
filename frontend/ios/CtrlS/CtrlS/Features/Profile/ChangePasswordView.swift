import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    private let onSave: (String, String) async -> Bool

    init(onSave: @escaping (String, String) async -> Bool) {
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Пароль") {
                    SecureField("Текущий пароль", text: $currentPassword)
                    SecureField("Новый пароль", text: $newPassword)
                    SecureField("Повторите новый пароль", text: $confirmPassword)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Смена пароля")
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

private extension ChangePasswordView {
    func submit() async {
        errorMessage = nil
        if currentPassword.count < 6 {
            errorMessage = "Введите текущий пароль."
            return
        }
        if newPassword.count < 6 {
            errorMessage = "Новый пароль минимум 6 символов."
            return
        }
        if newPassword != confirmPassword {
            errorMessage = "Пароли не совпадают."
            return
        }

        isSaving = true
        let ok = await onSave(currentPassword, newPassword)
        isSaving = false
        if ok {
            dismiss()
        } else {
            errorMessage = errorMessage ?? "Не удалось сменить пароль."
        }
    }
}

#Preview {
    ChangePasswordView { _, _ in true }
}
