import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var mode: Mode = .login

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    Text("Добро пожаловать")
                        .font(DS.Typography.title)
                        .foregroundStyle(DS.ColorToken.textPrimary)

                    Picker("Режим", selection: $mode) {
                        Text("Вход").tag(Mode.login)
                        Text("Регистрация").tag(Mode.register)
                    }
                    .pickerStyle(.segmented)

                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding()
                        .background(DS.ColorToken.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
                        )

                    SecureField("Пароль", text: $viewModel.password)
                        .padding()
                        .background(DS.ColorToken.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
                        )

                    if mode == .register {
                        TextField("Телефон (необязательно)", text: $viewModel.phone)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(DS.ColorToken.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
                            )
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(DS.Typography.caption)
                            .foregroundStyle(.red)
                    }

                    Button(action: {
                        Task {
                            if mode == .login {
                                await viewModel.login()
                            } else {
                                await viewModel.register()
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text(mode == .login ? "Войти" : "Зарегистрироваться")
                                .font(DS.Typography.body)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding()
                        .background(DS.ColorToken.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.xl)
            }
            .background(DS.ColorToken.screenBackground)
            .navigationTitle("Авторизация")
        }
    }
}

#Preview {
    AuthView()
}

private enum Mode {
    case login
    case register
}
