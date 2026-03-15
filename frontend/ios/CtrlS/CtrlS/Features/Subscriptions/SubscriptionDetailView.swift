import SwiftUI

struct SubscriptionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let subscription: Subscription
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Основное") {
                    detailRow(title: "Название", value: subscription.name)
                    detailRow(title: "Категория", value: subscription.category ?? "—")
                    detailRow(title: "Период", value: subscription.billingPeriod)
                    detailRow(title: "Статус", value: subscription.status.rawValue)
                }

                Section("Оплата") {
                    detailRow(title: "Сумма", value: subscription.formattedPrice)
                    detailRow(title: "Следующее списание", value: subscription.formattedDate)
                }

                Section {
                    Button("Редактировать") { onEdit() }
                    Button("Удалить", role: .destructive) { onDelete() }
                }
            }
            .navigationTitle(subscription.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(DS.ColorToken.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(DS.ColorToken.textPrimary)
        }
    }
}

#Preview {
    SubscriptionDetailView(
        subscription: Subscription(
            id: 1,
            name: "Netflix",
            category: "Стриминг",
            billingPeriod: "monthly",
            amount: 399,
            currency: "RUB",
            nextBillingDate: "2026-03-20",
            status: .active,
            formattedPrice: "399 ₽ / monthly",
            formattedDate: "20 мар."
        ),
        onEdit: {},
        onDelete: {}
    )
}
