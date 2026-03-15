import SwiftUI

struct EmailImportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EmailImportViewModel

    init(service: APIService) {
        _viewModel = StateObject(wrappedValue: EmailImportViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Источник") {
                    Toggle("Использовать демо‑данные", isOn: $viewModel.useSample)
                }

                if !viewModel.useSample {
                    Section("Почтовые данные") {
                        TextField("Email", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        SecureField("Пароль приложения", text: $viewModel.password)
                        Toggle("Согласен использовать пароль", isOn: $viewModel.consentToUsePassword)
                    }
                }

                Section("IMAP настройки") {
                    TextField("IMAP сервер", text: $viewModel.imapServer)
                        .textInputAutocapitalization(.never)
                    TextField("Папка", text: $viewModel.mailbox)
                        .textInputAutocapitalization(.never)
                    Stepper("Лимит: \(viewModel.limit)", value: $viewModel.limit, in: 1...200)
                }

                Section {
                    Button(viewModel.isLoading ? "Импорт..." : "Импортировать") {
                        Task { await viewModel.submit() }
                    }
                    .disabled(viewModel.isLoading)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                if let result = viewModel.result {
                    Section("Результат") {
                        Text("Создано подписок: \(result.created)")
                            .font(.footnote)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                        ForEach(result.parsed) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.service)
                                    .font(DS.Typography.body)
                                Text("\(item.amount ?? "—") \(item.currency ?? "")")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.ColorToken.textSecondary)
                                Text(item.sender)
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.ColorToken.textSecondary)
                                Text(item.subject)
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.ColorToken.textSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Импорт почты")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    EmailImportView(service: MockAPIService.shared)
}
