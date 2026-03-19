import SwiftUI

struct SubscriptionsView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var query = ""
    @State private var selectedTab: Tab = .all
    @State private var sortOption: SubscriptionsViewModel.SortOption = .nextDate
    @State private var isNotificationsPresented = false
    @State private var isCreatePresented = false
    @State private var isFiltersPresented = false
    @State private var editingSubscription: Subscription?
    @State private var detailSubscription: Subscription?
    @State private var deleteTarget: Subscription?
    @State private var showDeleteConfirm = false
    @State private var categoryFilter: Set<String> = []
    @State private var periodFilter: Set<String> = []
    @State private var minPrice: String = ""
    @State private var maxPrice: String = ""
    @StateObject private var viewModel = SubscriptionsViewModel(service: RealAPIService.shared)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    AndroidPageHeader(title: "Подписки", onNotifications: { isNotificationsPresented = true })
                    searchBar
                    filterTabs

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(DS.Typography.caption)
                            .foregroundStyle(.red)
                    }

                    subscriptionsList
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
            .sheet(isPresented: $isCreatePresented) {
                SubscriptionFormView(mode: .create) { payload in
                    try await viewModel.create(payload: payload, query: query, status: selectedTab.status)
                    viewModel.applyFilters(query: query, status: selectedTab.status, sort: sortOption)
                }
                .presentationDetents([.large])
            }
            .sheet(item: $editingSubscription) { subscription in
                SubscriptionFormView(mode: .edit(subscription)) { payload in
                    try await viewModel.update(id: subscription.id, payload: payload, query: query, status: selectedTab.status)
                    viewModel.applyFilters(query: query, status: selectedTab.status, sort: sortOption)
                }
                .presentationDetents([.large])
            }
            .sheet(item: $detailSubscription) { subscription in
                SubscriptionDetailView(
                    subscription: subscription,
                    onEdit: { editingSubscription = subscription },
                    onDelete: {
                        deleteTarget = subscription
                        showDeleteConfirm = true
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isFiltersPresented) {
                SubscriptionFiltersSheet(
                    categories: availableCategories,
                    categoryFilter: $categoryFilter,
                    periodFilter: $periodFilter,
                    minPrice: $minPrice,
                    maxPrice: $maxPrice,
                    sortOption: $sortOption,
                    onReset: resetFilters
                )
                .presentationDetents([.medium, .large])
            }
            .confirmationDialog("Удалить подписку?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    guard let target = deleteTarget else { return }
                    Task {
                        try? await viewModel.delete(id: target.id, query: query, status: selectedTab.status)
                        viewModel.applyFilters(query: query, status: selectedTab.status, sort: sortOption)
                        deleteTarget = nil
                    }
                }
                Button("Отмена", role: .cancel) {
                    deleteTarget = nil
                }
            }
            .task(id: session.accessToken) {
                await viewModel.load(query: query, status: selectedTab.status)
                viewModel.applyFilters(query: query, status: selectedTab.status, sort: sortOption)
            }
            .onChange(of: query) { _, newValue in
                viewModel.applyFilters(query: newValue, status: selectedTab.status, sort: sortOption)
            }
            .onChange(of: selectedTab) { _, newValue in
                viewModel.applyFilters(query: query, status: newValue.status, sort: sortOption)
            }
            .onChange(of: sortOption) { _, newValue in
                viewModel.applyFilters(query: query, status: selectedTab.status, sort: newValue)
            }
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
            case .all:
                return nil
            case .active:
                return .active
            case .paused:
                return .paused
            }
        }
    }

    var filteredSubscriptions: [Subscription] {
        viewModel.subscriptions.filter { subscription in
            let categoryMatch = categoryFilter.isEmpty || categoryFilter.contains(normalizedCategory(for: subscription))
            let periodMatch = periodFilter.isEmpty || periodFilter.contains(subscription.billingPeriod)
            let minMatch = minPriceDouble.map { subscription.amount >= $0 } ?? true
            let maxMatch = maxPriceDouble.map { subscription.amount <= $0 } ?? true
            return categoryMatch && periodMatch && minMatch && maxMatch
        }
    }

    var availableCategories: [String] {
        Array(Set(viewModel.allSubscriptions.map { normalizedCategory(for: $0) }))
            .sorted()
    }

    var searchBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DS.ColorToken.textSecondary)

                TextField("Поиск...", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DS.ColorToken.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .frame(height: 48)
            .background(DS.ColorToken.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(DS.ColorToken.border, lineWidth: 1)
            )

            Button(action: { isFiltersPresented = true }) {
                Image(systemName: activeFilterCount == 0 ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(activeFilterCount == 0 ? DS.ColorToken.textPrimary : DS.ColorToken.accent)
                    .frame(width: 48, height: 48)
                    .background(DS.ColorToken.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                            .stroke(DS.ColorToken.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        AndroidFilterChip(
                            title: "\(tab.rawValue) (\(count(for: tab)))",
                            isSelected: selectedTab == tab
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var subscriptionsList: some View {
        VStack(spacing: DS.Spacing.sm) {
            if filteredSubscriptions.isEmpty && viewModel.errorMessage == nil && !viewModel.isLoading {
                AndroidCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Подписок пока нет")
                            .font(DS.Typography.headline)
                            .foregroundStyle(DS.ColorToken.textPrimary)
                        Text("Добавьте первую подписку или измените фильтры.")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                        Button("Добавить подписку") {
                            isCreatePresented = true
                        }
                        .font(DS.Typography.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(DS.ColorToken.accent)
                        .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            ForEach(filteredSubscriptions) { item in
                AndroidCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.9))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(AppDisplay.firstLetter(from: item.title))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(item.title)
                                        .font(DS.Typography.headline)
                                        .foregroundStyle(DS.ColorToken.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.72)

                                    Text(item.status.rawValue)
                                        .font(DS.Typography.captionBold)
                                        .foregroundStyle(item.status == .paused ? .orange : DS.ColorToken.success)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background((item.status == .paused ? Color.orange : DS.ColorToken.success).opacity(0.12))
                                        .clipShape(Capsule())
                                }

                                Text(normalizedCategory(for: item))
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.ColorToken.textSecondary)
                            }

                            Spacer()

                            Menu {
                                Button("Открыть") {
                                    detailSubscription = item
                                }
                                Button("Редактировать") {
                                    editingSubscription = item
                                }
                                Button("Удалить", role: .destructive) {
                                    deleteTarget = item
                                    showDeleteConfirm = true
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(DS.ColorToken.textSecondary)
                                    .frame(width: 28, height: 28)
                            }
                        }

                        HStack(spacing: 14) {
                            Text("Стоимость: \(AppDisplay.formatAmount(item.amount, currency: item.currency))")
                            Text("Период: \(item.billingPeriod)")
                            Text("Следующий платёж: \(formattedDate(for: item))")
                        }
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.75)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        detailSubscription = item
                    }
                }
            }
        }
    }

    var activeFilterCount: Int {
        var count = 0
        if !categoryFilter.isEmpty { count += 1 }
        if !periodFilter.isEmpty { count += 1 }
        if !minPrice.isEmpty || !maxPrice.isEmpty { count += 1 }
        if sortOption != .nextDate { count += 1 }
        return count
    }

    var minPriceDouble: Double? {
        Double(minPrice.replacingOccurrences(of: ",", with: "."))
    }

    var maxPriceDouble: Double? {
        Double(maxPrice.replacingOccurrences(of: ",", with: "."))
    }

    func count(for tab: Tab) -> Int {
        switch tab {
        case .all:
            return viewModel.allSubscriptions.count
        case .active:
            return viewModel.allSubscriptions.filter { $0.status == .active }.count
        case .paused:
            return viewModel.allSubscriptions.filter { $0.status == .paused }.count
        }
    }

    func normalizedCategory(for subscription: Subscription) -> String {
        let raw = subscription.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? "Без категории" : raw
    }

    func formattedDate(for subscription: Subscription) -> String {
        guard let date = AppDisplay.parseAPIDate(subscription.nextBillingDate) else {
            return "—"
        }
        return AppDisplay.formatShortDate(date)
    }

    func resetFilters() {
        categoryFilter.removeAll()
        periodFilter.removeAll()
        minPrice = ""
        maxPrice = ""
        sortOption = .nextDate
    }
}

private struct SubscriptionFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    let categories: [String]
    @Binding var categoryFilter: Set<String>
    @Binding var periodFilter: Set<String>
    @Binding var minPrice: String
    @Binding var maxPrice: String
    @Binding var sortOption: SubscriptionsViewModel.SortOption
    let onReset: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Категории") {
                    if categories.isEmpty {
                        Text("Категории появятся после добавления подписок")
                            .font(DS.Typography.caption)
                    } else {
                        ForEach(categories, id: \.self) { category in
                            Toggle(category, isOn: binding(for: category))
                        }
                    }
                }

                Section("Период") {
                    Toggle("Ежемесячно", isOn: periodBinding("monthly"))
                    Toggle("Еженедельно", isOn: periodBinding("weekly"))
                    Toggle("Раз в полгода", isOn: periodBinding("half_year"))
                    Toggle("Ежегодно", isOn: periodBinding("yearly"))
                }

                Section("Диапазон цены") {
                    TextField("От", text: $minPrice)
                        .keyboardType(.decimalPad)
                    TextField("До", text: $maxPrice)
                        .keyboardType(.decimalPad)
                }

                Section("Сортировка") {
                    Picker("Сортировка", selection: $sortOption) {
                        ForEach(SubscriptionsViewModel.SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }
            .navigationTitle("Фильтр")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Сбросить") {
                        onReset()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func binding(for category: String) -> Binding<Bool> {
        Binding(
            get: { categoryFilter.contains(category) },
            set: { isOn in
                if isOn {
                    categoryFilter.insert(category)
                } else {
                    categoryFilter.remove(category)
                }
            }
        )
    }

    private func periodBinding(_ period: String) -> Binding<Bool> {
        Binding(
            get: { periodFilter.contains(period) },
            set: { isOn in
                if isOn {
                    periodFilter.insert(period)
                } else {
                    periodFilter.remove(period)
                }
            }
        )
    }
}
