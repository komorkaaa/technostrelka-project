import SwiftUI

struct AnalyticsView: View {
    @State private var isNotificationsPresented = false
    @State private var activeSheet: SheetDestination?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    metricsGrid
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
        }
    }
}

#Preview {
    AnalyticsView()
}

private extension AnalyticsView {
    var metricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.md), count: 2), spacing: DS.Spacing.md) {
            MetricCard(title: "Средний расход", value: "6 286 ₽", accent: .purple, icon: "dollarsign.circle")
                .onTapGesture { activeSheet = SheetDestination(title: "Средний расход") }
            MetricCard(title: "Тренд", value: "-4.4%", accent: .green, icon: "arrow.down.right")
                .onTapGesture { activeSheet = SheetDestination(title: "Тренд") }
            MetricCard(title: "Экономия", value: "1 240 ₽", accent: .green, icon: "leaf")
                .onTapGesture { activeSheet = SheetDestination(title: "Экономия") }
            MetricCard(title: "Эффективность", value: "87%", accent: .blue, icon: "percent")
                .onTapGesture { activeSheet = SheetDestination(title: "Эффективность") }
        }
    }

    var trendsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Динамика расходов")
                .font(DS.Typography.headline)
            LineChart()
            HStack(spacing: DS.Spacing.md) {
                StatBadge(title: "Минимум", value: "4 850 ₽", color: .purple)
                StatBadge(title: "Максимум", value: "7 150 ₽", color: .purple)
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
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("По категориям")
                .font(DS.Typography.headline)
            PieChart()
            VStack(spacing: DS.Spacing.sm) {
                LegendRow(color: .purple, title: "Стриминг", value: "998 ₽")
                    .onTapGesture { activeSheet = SheetDestination(title: "Стриминг") }
                LegendRow(color: .pink, title: "Музыка", value: "169 ₽")
                    .onTapGesture { activeSheet = SheetDestination(title: "Музыка") }
                LegendRow(color: .orange, title: "ПО", value: "4 579 ₽")
                    .onTapGesture { activeSheet = SheetDestination(title: "ПО") }
                LegendRow(color: .green, title: "Образование", value: "299 ₽")
                    .onTapGesture { activeSheet = SheetDestination(title: "Образование") }
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
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                let points: [CGPoint] = [
                    CGPoint(x: 0, y: h * 0.7),
                    CGPoint(x: w * 0.2, y: h * 0.55),
                    CGPoint(x: w * 0.4, y: h * 0.6),
                    CGPoint(x: w * 0.6, y: h * 0.45),
                    CGPoint(x: w * 0.8, y: h * 0.3),
                    CGPoint(x: w, y: h * 0.35)
                ]
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

private struct PieChart: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.orange.opacity(0.2), lineWidth: 28)
            Circle()
                .trim(from: 0, to: 0.76)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 28, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.76, to: 0.93)
                .stroke(Color.purple, style: StrokeStyle(lineWidth: 28, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.93, to: 0.98)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 28, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.98, to: 1.0)
                .stroke(Color.pink, style: StrokeStyle(lineWidth: 28, lineCap: .butt))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 160, height: 160)
        .frame(maxWidth: .infinity)
    }
}
