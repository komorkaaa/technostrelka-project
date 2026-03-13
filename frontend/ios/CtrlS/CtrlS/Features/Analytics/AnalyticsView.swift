import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var isNotificationsPresented = false
    @State private var activeSheet: SheetDestination?
    @StateObject private var viewModel = AnalyticsViewModel(service: RealAPIService.shared)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
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
                .padding(.bottom, DS.Spacing.xl)
            }
            .background(DS.ColorToken.screenBackground)
            .navigationTitle("Аналитика")
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
            .task(id: session.accessToken) { await viewModel.load() }
        }
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(SessionManager.shared)
}

private extension AnalyticsView {
    var metricsGrid: some View {
        let metrics = viewModel.overview?.metrics ?? placeholderMetrics
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.md), count: 2), spacing: DS.Spacing.md) {
            ForEach(metrics) { metric in
                MetricCard(
                    title: metric.title,
                    value: metric.value,
                    accent: color(from: metric.accentName),
                    icon: metric.icon
                )
                .onTapGesture { activeSheet = SheetDestination(title: metric.title) }
            }
        }
    }

    var trendsSection: some View {
        let chartPoints = viewModel.overview?.chartPoints ?? []
        return VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Динамика расходов")
                .font(DS.Typography.headline)
            LineChart(values: chartPoints.map { $0.value })
            HStack(spacing: DS.Spacing.md) {
                StatBadge(title: "Минимум", value: viewModel.overview?.chartMin ?? "—", color: .purple)
                StatBadge(title: "Максимум", value: viewModel.overview?.chartMax ?? "—", color: .purple)
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

    var categoriesSection: some View {
        let categories = viewModel.overview?.categories ?? []
        return VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("По категориям")
                .font(DS.Typography.headline)
            PieChart(segments: categories.map { PieSegment(value: $0.value, color: color(from: $0.colorName)) })
            VStack(spacing: DS.Spacing.sm) {
                if categories.isEmpty {
                    Text("Нет данных")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
                ForEach(categories) { item in
                    LegendRow(color: color(from: item.colorName), title: item.title, value: item.formattedValue)
                        .onTapGesture { activeSheet = SheetDestination(title: item.title) }
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

    var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Рекомендации по экономии")
                .font(DS.Typography.headline)
            VStack(alignment: .leading, spacing: 6) {
                Text("• Годовая оплата Adobe CC — экономия до 20%")
                Text("• Семейная подписка Spotify вместо индивидуальной")
                Text("• Объедините Яндекс Плюс и Okko в один пакет")
            }
            .font(DS.Typography.caption)
            .foregroundStyle(DS.ColorToken.textSecondary)
        }
        .padding(DS.Spacing.md)
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .onTapGesture { activeSheet = SheetDestination(title: "Рекомендации") }
    }

    var placeholderMetrics: [AnalyticsMetric] {
        [
            AnalyticsMetric(title: "Средний расход", value: "—", accentName: "purple", icon: "dollarsign.circle"),
            AnalyticsMetric(title: "Тренд", value: "—", accentName: "green", icon: "arrow.down.right"),
            AnalyticsMetric(title: "Экономия", value: "—", accentName: "green", icon: "leaf"),
            AnalyticsMetric(title: "Эффективность", value: "—", accentName: "blue", icon: "percent")
        ]
    }

    func color(from name: String) -> Color {
        switch name {
        case "black": return .black
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .gray
        }
    }
}

private struct SheetDestination: Identifiable {
    let id = UUID()
    let title: String
}

private struct MetricCard: View {
    let title: String
    let value: String
    let accent: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(accent)
                    .frame(width: 28, height: 28)
                    .background(accent.opacity(0.15))
                    .clipShape(Circle())
                Spacer()
            }
            Text(title)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.ColorToken.textSecondary)
            Text(value)
                .font(DS.Typography.headline)
                .foregroundStyle(DS.ColorToken.textPrimary)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(DS.ColorToken.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .stroke(DS.ColorToken.chipBackground, lineWidth: 1)
        )
    }
}

private struct StatBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.ColorToken.textSecondary)
            Text(value)
                .font(DS.Typography.body)
                .foregroundStyle(color)
        }
        .padding(DS.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct LegendRow: View {
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.ColorToken.textPrimary)
            Spacer()
            Text(value)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.ColorToken.textSecondary)
        }
    }
}

private struct LineChart: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                guard values.count > 1, let minValue = values.min(), let maxValue = values.max(), maxValue > minValue else {
                    path.move(to: CGPoint(x: 0, y: h * 0.6))
                    path.addLine(to: CGPoint(x: w, y: h * 0.6))
                    return
                }

                let stepX = w / CGFloat(values.count - 1)
                let range = maxValue - minValue
                let points = values.enumerated().map { index, value -> CGPoint in
                    let x = CGFloat(index) * stepX
                    let normalized = (value - minValue) / range
                    let y = h - (CGFloat(normalized) * h)
                    return CGPoint(x: x, y: y)
                }

                path.move(to: points[0])
                for p in points.dropFirst() {
                    path.addLine(to: p)
                }
            }
            .stroke(DS.ColorToken.accent, lineWidth: 3)
        }
        .frame(height: 140)
    }
}

private struct PieSegment: Identifiable {
    let id = UUID()
    let value: Double
    let color: Color
}

private struct PieChart: View {
    let segments: [PieSegment]

    var body: some View {
        let total = segments.reduce(0) { $0 + $1.value }

        ZStack {
            Circle()
                .stroke(DS.ColorToken.chipBackground, lineWidth: 28)

            if total > 0 {
                ForEach(segments.indices, id: \.self) { index in
                    let start = segments.prefix(index).reduce(0) { $0 + $1.value } / total
                    let end = (segments.prefix(index + 1).reduce(0) { $0 + $1.value }) / total
                    Circle()
                        .trim(from: start, to: end)
                        .stroke(segments[index].color, style: StrokeStyle(lineWidth: 28, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
            }
        }
        .frame(width: 160, height: 160)
        .frame(maxWidth: .infinity)
    }
}
