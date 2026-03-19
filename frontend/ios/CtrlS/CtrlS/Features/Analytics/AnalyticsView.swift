import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var isNotificationsPresented = false
    @State private var isCategoryPickerPresented = false
    @StateObject private var viewModel = AnalyticsViewModel(service: RealAPIService.shared)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    AndroidPageHeader(title: "Аналитика", accentTitle: false, onNotifications: { isNotificationsPresented = true })
                    periodSelector
                    categorySelector

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    metricsGrid

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(DS.Typography.caption)
                            .foregroundStyle(.red)
                    }

                    trendsSection
                    categoriesSection
                    recommendationsSection
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
            .confirmationDialog("Категории", isPresented: $isCategoryPickerPresented, titleVisibility: .visible) {
                Button("Все категории") {
                    Task { await viewModel.load(period: viewModel.period, category: nil) }
                }

                ForEach(viewModel.availableCategories, id: \.self) { category in
                    Button(category) {
                        Task { await viewModel.load(period: viewModel.period, category: category) }
                    }
                }
            }
            .task(id: session.accessToken) {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load(period: viewModel.period, category: viewModel.selectedCategory)
            }
        }
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(SessionManager.shared)
}

private extension AnalyticsView {
    var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach([AnalyticsPeriod.month, .halfYear, .year], id: \.self) { period in
                    Button(action: {
                        Task { await viewModel.load(period: period, category: viewModel.selectedCategory) }
                    }) {
                        AndroidFilterChip(title: title(for: period), isSelected: viewModel.period == period)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var categorySelector: some View {
        Button(action: { isCategoryPickerPresented = true }) {
            AndroidCard {
                HStack {
                    Text(viewModel.selectedCategory ?? "Все категории")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.ColorToken.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .rotationEffect(.degrees(90))
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    var metricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.sm), count: 2), spacing: DS.Spacing.sm) {
            ForEach(viewModel.displayMetrics) { metric in
                AndroidCard {
                    VStack(alignment: .leading, spacing: 10) {
                        AndroidIconTile(
                            systemName: metric.icon,
                            foreground: accentColor(for: metric.accentName),
                            background: accentBackground(for: metric.accentName),
                            size: 30
                        )

                        Text(metric.title)
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.ColorToken.textSecondary)

                        Text(metric.value)
                            .font(DS.Typography.headline)
                            .foregroundStyle(DS.ColorToken.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                }
            }
        }
    }

    var trendsSection: some View {
        AndroidCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Динамика расходов")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)

                if let overview = viewModel.overview, !overview.chartPoints.isEmpty {
                    CompactAnalyticsLineChart(points: overview.chartPoints)
                    HStack(spacing: DS.Spacing.sm) {
                        minMaxCard(title: "Минимум", value: overview.chartMin)
                        minMaxCard(title: "Максимум", value: overview.chartMax)
                    }
                } else {
                    Text("Нет данных для отображения")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
            }
        }
    }

    var categoriesSection: some View {
        AndroidCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("По категориям")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)

                if let categories = viewModel.overview?.categories, !categories.isEmpty {
                    CompactDonutChart(segments: categories)
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 10) {
                        ForEach(categories) { category in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(accentColor(for: category.colorName))
                                    .frame(width: 10, height: 10)

                                Text(category.title)
                                    .font(DS.Typography.captionBold)
                                    .foregroundStyle(DS.ColorToken.textPrimary)

                                Spacer()

                                Text(category.formattedValue)
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.ColorToken.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                            }
                        }
                    }
                } else {
                    Text("Нет данных по категориям")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
            }
        }
    }

    var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Рекомендации по экономии")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)

            Text("Годовая оплата сервисов с высокой стоимостью часто экономит до 20%.")
            Text("Семейные тарифы выгоднее, если у тебя несколько активных подписок одного типа.")
            Text("Проверь категории с наибольшим расходом: там обычно быстрее всего находится экономия.")
        }
        .font(DS.Typography.caption)
        .foregroundStyle(DS.ColorToken.textSecondary)
        .padding(DS.Spacing.md)
        .background(DS.ColorToken.softGreen)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(DS.ColorToken.success.opacity(0.2), lineWidth: 1)
        )
    }

    func minMaxCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.ColorToken.textSecondary)
            Text(value)
                .font(DS.Typography.body)
                .foregroundStyle(DS.ColorToken.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(DS.ColorToken.softPurple)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func title(for period: AnalyticsPeriod) -> String {
        switch period {
        case .month:
            return "Месяц"
        case .halfYear:
            return "Полгода"
        case .year:
            return "Год"
        }
    }

    func accentColor(for name: String) -> Color {
        switch name {
        case "green":
            return DS.ColorToken.success
        case "blue":
            return DS.ColorToken.infoBlue
        case "orange":
            return DS.ColorToken.warning
        case "red":
            return .red
        case "pink":
            return .pink
        case "black":
            return .black
        default:
            return DS.ColorToken.accent
        }
    }

    func accentBackground(for name: String) -> Color {
        switch name {
        case "green":
            return DS.ColorToken.softGreen
        case "blue":
            return DS.ColorToken.softBlue
        case "orange":
            return DS.ColorToken.softOrange
        case "red":
            return DS.ColorToken.softRed
        default:
            return DS.ColorToken.softPurple
        }
    }
}

private struct CompactAnalyticsLineChart: View {
    let points: [AnalyticsChartPoint]

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geometry in
                let values = points.map(\.value)
                let minimum = values.min() ?? 0
                let maximum = values.max() ?? 1
                let range = max(maximum - minimum, 1.0)
                let height = geometry.size.height
                let width = geometry.size.width
                let stepX = points.count > 1 ? width / CGFloat(points.count - 1) : 0

                ZStack {
                    VStack(spacing: height / 4) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(DS.ColorToken.border.opacity(0.8))
                                .frame(height: 1)
                        }
                    }

                    Path { path in
                        for (index, point) in points.enumerated() {
                            let x = CGFloat(index) * stepX
                            let normalized = CGFloat((point.value - minimum) / range)
                            let y = height - (normalized * (height - 12)) - 6

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(DS.ColorToken.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        let x = CGFloat(index) * stepX
                        let normalized = CGFloat((point.value - minimum) / range)
                        let y = height - (normalized * (height - 12)) - 6

                        Circle()
                            .fill(DS.ColorToken.accent)
                            .frame(width: 12, height: 12)
                            .position(x: x, y: y)
                    }
                }
            }
            .frame(height: 180)
            .padding(.top, 4)

            HStack {
                ForEach(points) { point in
                    Text(point.label)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }
}

private struct CompactDonutChart: View {
    let segments: [AnalyticsCategoryBreakdown]

    var body: some View {
        let total = segments.reduce(0) { $0 + $1.value }

        ZStack {
            Circle()
                .stroke(DS.ColorToken.chipBackground, lineWidth: 28)

            if total > 0 {
                ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                    let start = segments.prefix(index).reduce(0) { $0 + $1.value } / total
                    let end = segments.prefix(index + 1).reduce(0) { $0 + $1.value } / total

                    Circle()
                        .trim(from: start, to: end)
                        .stroke(color(for: segment.colorName), style: StrokeStyle(lineWidth: 28, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
            }

            Text("Категории")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DS.ColorToken.textSecondary)
        }
        .frame(width: 180, height: 180)
    }

    private func color(for name: String) -> Color {
        switch name {
        case "green":
            return DS.ColorToken.success
        case "blue":
            return DS.ColorToken.infoBlue
        case "orange":
            return DS.ColorToken.warning
        case "red":
            return .red
        case "pink":
            return .pink
        case "black":
            return .black
        default:
            return DS.ColorToken.accent
        }
    }
}
