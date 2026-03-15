import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var isNotificationsPresented = false
    @State private var activeSheet: SheetDestination?
    @State private var isImportPresented = false
    @State private var showLogoutConfirm = false
    @StateObject private var viewModel = ProfileViewModel(service: RealAPIService.shared)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
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
                    supportSection
                    logoutButton
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.xl)
            }
            .background(DS.ColorToken.screenBackground)
            .navigationTitle("Профиль")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isNotificationsPresented = true }) {
                        Image(systemName: "bell")
                            .foregroundStyle(DS.ColorToken.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $isNotificationsPresented) {
                NotificationsView()
            }
            .sheet(isPresented: $isImportPresented) {
                EmailImportView(service: RealAPIService.shared)
            }
            .sheet(item: $activeSheet) { sheet in
                PlaceholderView(title: sheet.title)
            }
            .task(id: session.accessToken) { await viewModel.load() }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(SessionManager.shared)
}

private extension ProfileView {
    var profileCard: some View {
        HStack(spacing: DS.Spacing.md) {
            Circle()
                .fill(DS.ColorToken.accent)
                .frame(width: 56, height: 56)
                .overlay(
                    Text(initials(from: viewModel.profile?.email))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.profile?.email ?? "—")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Text(viewModel.profile?.phone ?? "Телефон не указан")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
            Spacer()
        }
        .padding(DS.Spacing.md)
        .background(DS.ColorToken.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
        )
    }

    var statsRow: some View {
        HStack(spacing: DS.Spacing.md) {
            StatMini(title: "Подписок", value: viewModel.stats?.subscriptions ?? "—")
            StatMini(title: "В месяц", value: viewModel.stats?.monthly ?? "—")
            StatMini(title: "Экономия", value: viewModel.stats?.savings ?? "—")
        }
    }

    var settingsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionTitle("Настройки")
            SettingRow(icon: "person", title: "Личная информация", subtitle: "Имя, email, телефон")
                .onTapGesture { activeSheet = SheetDestination(title: "Личная информация") }
            SettingRow(icon: "bell", title: "Уведомления", subtitle: "Настройка оповещений")
                .onTapGesture { activeSheet = SheetDestination(title: "Уведомления") }
            SettingRow(icon: "creditcard", title: "Способы оплаты", subtitle: "Карты и интеграции")
                .onTapGesture { activeSheet = SheetDestination(title: "Способы оплаты") }
            SettingRow(icon: "tray.and.arrow.down", title: "Импорт из почты", subtitle: "IMAP и демо‑данные")
                .onTapGesture { isImportPresented = true }
        }
    }

    var preferencesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionTitle("Предпочтения")
            ToggleRow(icon: "bell.badge", title: "Push‑уведомления", isOn: true)
            SettingRow(icon: "globe", title: "Язык и регион", subtitle: "Русский, Москва (GMT+3)")
                .onTapGesture { activeSheet = SheetDestination(title: "Язык и регион") }
        }
    }

    var securitySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionTitle("Безопасность")
            SettingRow(icon: "lock.shield", title: "Пароль и безопасность", subtitle: "Смена пароля, 2FA")
                .onTapGesture { activeSheet = SheetDestination(title: "Пароль и безопасность") }
        }
    }

    var supportSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionTitle("Прочее")
            SettingRow(icon: "questionmark.circle", title: "Помощь и поддержка", subtitle: "FAQ, контакты")
                .onTapGesture { activeSheet = SheetDestination(title: "Помощь и поддержка") }
            SettingRow(icon: "arrow.down.circle", title: "Экспорт данных", subtitle: "Скачать все данные")
                .onTapGesture { activeSheet = SheetDestination(title: "Экспорт данных") }
            SettingRow(icon: "arrow.clockwise", title: "Обновить данные", subtitle: "Синхронизировать профиль")
                .onTapGesture { Task { await viewModel.load() } }
        }
    }

    var logoutButton: some View {
        Button(action: { showLogoutConfirm = true }) {
            Text("Выйти из аккаунта")
                .font(DS.Typography.body)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.sm)
                .background(DS.ColorToken.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                        .stroke(.red.opacity(0.4), lineWidth: 1)
                )
        }
        .padding(.top, DS.Spacing.sm)
        .alert("Выйти из аккаунта?", isPresented: $showLogoutConfirm) {
            Button("Выйти", role: .destructive) {
                SessionManager.shared.logout()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вы уверены, что хотите выйти?")
        }
    }

    func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(DS.Typography.caption)
            .foregroundStyle(DS.ColorToken.textSecondary)
            .padding(.top, DS.Spacing.xs)
    }

    func initials(from email: String?) -> String {
        guard let email, let first = email.first else { return "?" }
        return String(first).uppercased()
    }
}

private struct SheetDestination: Identifiable {
    let id = UUID()
    let title: String
}

private struct StatMini: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(DS.Typography.headline)
                .foregroundStyle(DS.ColorToken.accent)
            Text(title)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.ColorToken.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(DS.ColorToken.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
        )
    }
}

private struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(DS.ColorToken.accent)
                .frame(width: 36, height: 36)
                .background(DS.ColorToken.chipBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Text(subtitle)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(DS.ColorToken.textSecondary)
        }
        .padding(DS.Spacing.md)
        .background(DS.ColorToken.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
        )
    }
}

private struct ToggleRow: View {
    let icon: String
    let title: String
    @State var isOn: Bool

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(DS.ColorToken.accent)
                .frame(width: 36, height: 36)
                .background(DS.ColorToken.chipBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(title)
                .font(DS.Typography.body)
                .foregroundStyle(DS.ColorToken.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(DS.Spacing.md)
        .background(DS.ColorToken.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
        )
    }
}
