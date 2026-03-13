import SwiftUI

struct ProfileView: View {
    @State private var isNotificationsPresented = false
    @State private var activeSheet: SheetDestination?
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    profileCard
                    statsRow
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
            .sheet(item: $activeSheet) { sheet in
                PlaceholderView(title: sheet.title)
            }
        }
    }
}

#Preview {
    ProfileView()
}

private extension ProfileView {
    var profileCard: some View {
        HStack(spacing: DS.Spacing.md) {
            Circle()
                .fill(DS.ColorToken.accent)
                .frame(width: 56, height: 56)
                .overlay(
                    Text("П")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text("Пётр Иванов")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Text("petr@example.com")
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
            StatMini(title: "Подписок", value: "8")
            StatMini(title: "В месяц", value: "6.8K")
            StatMini(title: "Экономия", value: "1.2K")
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
