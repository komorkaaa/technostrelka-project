import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var isNotificationsPresented = false
    @State private var isImportPresented = false
    @State private var isEditProfilePresented = false
    @State private var isChangePasswordPresented = false
    @State private var isNotificationSettingsPresented = false
    @State private var isPaymentMethodsPresented = false
    @State private var isLanguagePresented = false
    @State private var isSupportPresented = false
    @State private var showLogoutConfirm = false
    @State private var pushEnabled = true
    @State private var notificationLeadDays = 3
    @StateObject private var viewModel = ProfileViewModel(service: RealAPIService.shared)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    AndroidPageHeader(title: "Профиль", onNotifications: { isNotificationsPresented = true })
                    profileCard
                    statsRow

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(DS.Typography.caption)
                            .foregroundStyle(.red)
                    }

                    settingsSection
                    preferencesSection
                    securitySection
                    miscSection
                    logoutButton
                    versionLabel
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, 96)
            }
            .background(DS.ColorToken.screenBackground)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isNotificationsPresented) {
                NotificationsView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isImportPresented) {
                EmailImportView(service: RealAPIService.shared)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isEditProfilePresented) {
                ProfileEditView(email: viewModel.profile?.email, phone: viewModel.profile?.phone) { email, phone in
                    await viewModel.updateProfile(email: email, phone: phone)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isChangePasswordPresented) {
                ChangePasswordView { current, new in
                    await viewModel.changePassword(current: current, new: new)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isNotificationSettingsPresented) {
                NotificationSettingsView(
                    pushEnabled: $pushEnabled,
                    notificationLeadDays: $notificationLeadDays
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $isPaymentMethodsPresented) {
                PaymentMethodsView()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $isLanguagePresented) {
                LanguageRegionView()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $isSupportPresented) {
                SupportView()
                    .presentationDetents([.medium])
            }
            .task(id: session.accessToken) {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(SessionManager.shared)
}

private extension ProfileView {
    var profileCard: some View {
        AndroidCard {
            HStack(spacing: DS.Spacing.md) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [DS.ColorToken.accent, DS.ColorToken.accentPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                    .overlay(
                        Text(AppDisplay.firstLetter(from: viewModel.profile?.email))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.profile?.email ?? "—")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(viewModel.profile?.phone ?? "Телефон не указан")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                }

                Spacer()
            }
        }
    }

    var statsRow: some View {
        HStack(spacing: DS.Spacing.sm) {
            profileStat(title: "Подписок", value: viewModel.stats?.subscriptions ?? "—", color: DS.ColorToken.accent)
            profileStat(title: "В месяц", value: viewModel.stats?.monthly ?? "—", color: DS.ColorToken.accent)
            profileStat(title: "Экономия", value: viewModel.stats?.savings ?? "—", color: DS.ColorToken.success)
        }
    }

    func profileStat(title: String, value: String, color: Color) -> some View {
        AndroidCard {
            VStack(spacing: 6) {
                    Text(value)
                        .font(DS.Typography.headline)
                        .foregroundStyle(color)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 76)
        }
    }

    var settingsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            AndroidSectionCaption(text: "Настройки")
            ProfileSettingsGroup {
                ProfileSettingsRow(
                    icon: "person.crop.circle",
                    iconColor: DS.ColorToken.accent,
                    iconBackground: DS.ColorToken.softPurple,
                    title: "Личная информация",
                    subtitle: "Имя, email, телефон"
                ) { isEditProfilePresented = true }

                Divider()
                    .padding(.leading, 56)

                ProfileSettingsRow(
                    icon: "bell",
                    iconColor: DS.ColorToken.infoBlue,
                    iconBackground: DS.ColorToken.softBlue,
                    title: "Уведомления",
                    subtitle: "Настройка оповещений"
                ) { isNotificationSettingsPresented = true }

                Divider()
                    .padding(.leading, 56)

                ProfileSettingsRow(
                    icon: "creditcard",
                    iconColor: DS.ColorToken.success,
                    iconBackground: DS.ColorToken.softGreen,
                    title: "Способы оплаты",
                    subtitle: "Карты и интеграции"
                ) { isPaymentMethodsPresented = true }
            }
        }
    }

    var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            AndroidSectionCaption(text: "Предпочтения")
            ProfileSettingsGroup {
                ProfileToggleSettingsRow(
                    icon: "bell.badge",
                    iconColor: DS.ColorToken.warning,
                    iconBackground: DS.ColorToken.softOrange,
                    title: "Push-уведомления",
                    subtitle: "О платежах и событиях",
                    isOn: $pushEnabled
                )

                Divider()
                    .padding(.leading, 56)

                ProfileSettingsRow(
                    icon: "textformat",
                    iconColor: DS.ColorToken.accent,
                    iconBackground: DS.ColorToken.softPurple,
                    title: "Язык и регион",
                    subtitle: "Русский, Киров (GMT+3)"
                ) { isLanguagePresented = true }
            }
        }
    }

    var securitySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            AndroidSectionCaption(text: "Безопасность")
            ProfileSettingsGroup {
                ProfileSettingsRow(
                    icon: "shield.lefthalf.filled",
                    iconColor: .red,
                    iconBackground: DS.ColorToken.softRed,
                    title: "Пароль и безопасность",
                    subtitle: "Смена пароля, 2FA"
                ) { isChangePasswordPresented = true }
            }
        }
    }

    var miscSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            AndroidSectionCaption(text: "Прочее")
            ProfileSettingsGroup {
                ProfileSettingsRow(
                    icon: "questionmark.circle",
                    iconColor: DS.ColorToken.infoBlue,
                    iconBackground: DS.ColorToken.softBlue,
                    title: "Помощь и поддержка",
                    subtitle: "FAQ, контакты"
                ) { isSupportPresented = true }

                Divider()
                    .padding(.leading, 56)

                ProfileSettingsRow(
                    icon: "tray.and.arrow.down",
                    iconColor: DS.ColorToken.textSecondary,
                    iconBackground: DS.ColorToken.chipBackground,
                    title: "Импорт данных",
                    subtitle: "Импорт из почты"
                ) { isImportPresented = true }
            }
        }
    }

    var logoutButton: some View {
        Button(action: { showLogoutConfirm = true }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text("Выйти из аккаунта")
                    .font(DS.Typography.subheadline)
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DS.ColorToken.softRed.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(.red.opacity(0.28), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .alert("Выйти из аккаунта?", isPresented: $showLogoutConfirm) {
            Button("Выйти", role: .destructive) {
                SessionManager.shared.logout()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вы уверены, что хотите выйти?")
        }
    }

    var versionLabel: some View {
        Text("CtrlS v1.0.0")
            .font(DS.Typography.caption)
            .foregroundStyle(DS.ColorToken.textSecondary)
            .frame(maxWidth: .infinity)
    }
}

private struct ProfileSettingsGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        AndroidCard(padding: 0) {
            VStack(spacing: 0) {
                content
            }
        }
    }
}

private struct ProfileSettingsRow: View {
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AndroidIconTile(systemName: icon, foreground: iconColor, background: iconBackground)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.ColorToken.textPrimary)
                    Text(subtitle)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
            .padding(DS.Spacing.md)
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileToggleSettingsRow: View {
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            AndroidIconTile(systemName: icon, foreground: iconColor, background: iconBackground)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Text(subtitle)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(DS.Spacing.md)
    }
}

private struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var pushEnabled: Bool
    @Binding var notificationLeadDays: Int

    var body: some View {
        NavigationStack {
            Form {
                Section("Оповещения") {
                    Toggle("Push-уведомления", isOn: $pushEnabled)
                    Stepper("Показывать списания за \(notificationLeadDays) дн.", value: $notificationLeadDays, in: 1...14)
                }
            }
            .navigationTitle("Уведомления")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

private struct PaymentMethodsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Способы оплаты") {
                    Label("Банковские карты появятся в следующем обновлении", systemImage: "creditcard")
                    Label("Интеграции с Apple Pay и Google Pay готовятся", systemImage: "wallet.pass")
                }
            }
            .navigationTitle("Способы оплаты")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

private struct LanguageRegionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var language = "Русский"
    @State private var region = "Киров (GMT+3)"

    var body: some View {
        NavigationStack {
            Form {
                Section("Язык") {
                    Picker("Язык", selection: $language) {
                        Text("Русский").tag("Русский")
                        Text("English").tag("English")
                    }
                }

                Section("Регион") {
                    Picker("Часовой пояс", selection: $region) {
                        Text("Киров (GMT+3)").tag("Киров (GMT+3)")
                        Text("Москва (GMT+3)").tag("Москва (GMT+3)")
                    }
                }
            }
            .navigationTitle("Язык и регион")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

private struct SupportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Помощь") {
                    Label("FAQ по подпискам и уведомлениям", systemImage: "questionmark.circle")
                    Label("support@ctrls.app", systemImage: "envelope")
                    Label("Telegram: @ctrls_support", systemImage: "paperplane")
                }
            }
            .navigationTitle("Помощь и поддержка")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}
