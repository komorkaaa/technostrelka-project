import Foundation
import Combine

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var overview: AnalyticsOverview?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var period: AnalyticsPeriod = .month
    @Published var selectedCategory: String? = nil

    private let service: APIService

    init(service: APIService) {
        self.service = service
    }

    func load(period: AnalyticsPeriod? = nil, category: String? = nil) async {
        do {
            isLoading = true
            errorMessage = nil
            if let period { self.period = period }
            self.selectedCategory = category
            overview = try await service.fetchAnalyticsOverview(
                period: self.period,
                category: self.selectedCategory
            )
        } catch let apiError as APIError {
            errorMessage = apiError.message
            overview = nil
        } catch {
            errorMessage = error.localizedDescription
            overview = nil
        }
        isLoading = false
    }

    var availableCategories: [String] {
        overview?.categories.map { $0.title } ?? []
    }

    var displayMetrics: [AnalyticsMetric] {
        guard let points = overview?.chartPoints, !points.isEmpty else {
            return [
                AnalyticsMetric(title: "Средний расход", value: "—", accentName: "purple", icon: "dollarsign.circle"),
                AnalyticsMetric(title: "Тренд", value: "—", accentName: "green", icon: "arrow.down.right"),
                AnalyticsMetric(title: "Экономия", value: "—", accentName: "green", icon: "leaf"),
                AnalyticsMetric(title: "Эффективность", value: "—", accentName: "blue", icon: "percent")
            ]
        }

        let values = points.map(\.value)
        let sum = values.reduce(0, +)
        let average = sum / Double(values.count)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 0
        let first = values.first ?? 0
        let last = values.last ?? 0
        let trend = first > 0 ? ((last - first) / first) * 100.0 : 0
        let efficiency = maximum > 0 ? (average / maximum) * 100.0 : 0

        return [
            AnalyticsMetric(title: "Средний расход", value: AppDisplay.formatAmount(average, currency: "RUB"), accentName: "purple", icon: "dollarsign.circle"),
            AnalyticsMetric(title: "Тренд", value: String(format: "%.1f%%", trend), accentName: "green", icon: "arrow.down.right"),
            AnalyticsMetric(title: "Экономия", value: AppDisplay.formatAmount(maximum - minimum, currency: "RUB"), accentName: "green", icon: "leaf"),
            AnalyticsMetric(title: "Эффективность", value: String(format: "%.0f%%", efficiency), accentName: "blue", icon: "percent")
        ]
    }
}
