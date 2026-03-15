import SwiftUI

struct SubscriptionsView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var query = ""
    @State private var selectedTab: Tab = .all
    @State private var isNotificationsPresented = false
    @State private var isCreatePresented = false
    @State private var editingSubscription: Subscription?
    @State private var deleteTarget: Subscription?
    @State private var showDeleteConfirm = false
    @State private var activeSheet: SheetDestination?
    @StateObject private var viewModel = SubscriptionsViewModel(service: RealAPIService.shared)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    searchBar
                    filterTabs
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(DS.Typography.caption)
                            .foregroundStyle(.red)
                    }
                    subscriptionsList
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.xl)
            }
            .background(DS.ColorToken.screenBackground)
            .navigationTitle("Подписки")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isNotificationsPresented = true }) {
                        Image(systemName: "bell")
                            .foregroundStyle(DS.ColorToken.textSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isCreatePresented = true }) {
                        Image(systemName: "plus")
                            .foregroundStyle(DS.ColorToken.accent)
                    }
                }
            }
            .sheet(isPresented: $isNotificationsPresented) {
                NotificationsView()
            }
            .sheet(isPresented: $isCreatePresented) {
                SubscriptionFormView(mode: .create) { payload in
                    try await viewModel.create(payload: payload, query: query, status: selectedTab.status)
                }
            }
            .sheet(item: $editingSubscription) { subscription in
                SubscriptionFormView(mode: .edit(subscription)) { payload in
                    try await viewModel.update(id: subscription.id, payload: payload, query: query, status: selectedTab.status)
                }
            }
            .sheet(item: $activeSheet) { sheet in
                PlaceholderView(title: sheet.title)
            }
            .confirmationDialog("Удалить подписку?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    guard let target = deleteTarget else { return }
                    Task { try? await viewModel.delete(id: target.id, query: query, status: selectedTab.status) }
                }
                Button("Отмена", role: .cancel) {
                    deleteTarget = nil
                }
            }
            .task(id: session.accessToken) { await viewModel.load(query: query, status: selectedTab.status) }
        }
    }
}

#Preview {
    SubscriptionsView()
        .environmentObject(SessionManager.shared)
}

private extension SubscriptionsView {
    enum Tab: String, CaseIterable {
        case all = "Все"
        case active = "Активные"
        case paused = "На паузе"

        var status: SubscriptionStatus? {
            switch self {
            case .all: return nil
            case .active: return .active
            case .paused: return .paused
            }
        }
    }

    var searchBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DS.ColorToken.textSecondary)
                TextField("Поиск...", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(DS.ColorToken.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
            )

            Button(action: {}) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.ColorToken.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
                    )
            }
            .onTapGesture { activeSheet = SheetDestination(title: "Фильтры") }
        }
        .onChange(of: query) { _, newValue in
            Task { await viewModel.load(query: newValue, status: selectedTab.status) }
        }
    }

    var filterTabs: some View {
        HStack(spacing: DS.Spacing.sm) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.rawValue)
                        .font(DS.Typography.caption)
                        .foregroundStyle(selectedTab == tab ? .white : DS.ColorToken.textSecondary)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(selectedTab == tab ? DS.ColorToken.accent : DS.ColorToken.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
                        )
                }
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            Task { await viewModel.load(query: query, status: newValue.status) }
        }
    }

    var subscriptionsList: some View {
        VStack(spacing: DS.Spacing.sm) {
            ForEach(viewModel.subscriptions) { item in
                SubscriptionRow(
                    title: item.title,
                    subtitle: item.subtitle,
                    price: item.price,
                    status: item.status.rawValue,
                    date: item.date
                )
                .onTapGesture { activeSheet = SheetDestination(title: item.title) }
                .contextMenu {
                    Button("Редактировать") {
                        editingSubscription = item
                    }
                    Button("Удалить", role: .destructive) {
                        deleteTarget = item
                        showDeleteConfirm = true
                    }
                }
            }
        }
    }
}

private struct SheetDestination: Identifiable {
    let id = UUID()
    let title: String
}

private struct SubscriptionRow: View {
    let title: String
    let subtitle: String
    let price: String
    let status: String
    let date: String

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DS.ColorToken.chipBackground)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(title.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DS.ColorToken.accent)
                )
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.ColorToken.textPrimary)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
                Text(status)
                    .font(DS.Typography.caption)
                    .foregroundStyle(status == "На паузе" ? .orange : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(DS.ColorToken.chipBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(subtitle)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.ColorToken.textSecondary)
                HStack {
                    Text(price)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.accent)
                    Spacer()
                    Text(date)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
            }
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
