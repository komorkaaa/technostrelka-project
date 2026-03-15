import SwiftUI

struct SubscriptionFormView: View {
    enum Mode {
        case create
        case edit(Subscription)

        var title: String {
            switch self {
            case .create: return "Новая подписка"
            case .edit: return "Редактировать подписку"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var amount: String
    @State private var currency: String
    @State private var billingPeriod: String
    @State private var category: String
    @State private var hasNextBillingDate: Bool
    @State private var nextBillingDate: Date
    @State private var errorMessage: String?
    @State private var isSaving = false

    private let mode: Mode
    private let onSubmit: (SubscriptionPayload) async throws -> Void

    init(mode: Mode, onSubmit: @escaping (SubscriptionPayload) async throws -> Void) {
        self.mode = mode
        self.onSubmit = onSubmit

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _amount = State(initialValue: "")
            _currency = State(initialValue: "RUB")
            _billingPeriod = State(initialValue: "monthly")
            _category = State(initialValue: "")
            _hasNextBillingDate = State(initialValue: false)
            _nextBillingDate = State(initialValue: Date())
        case .edit(let subscription):
            let initialAmount = Self.formatAmount(subscription.amount)
            let initialDate = Self.parseDate(subscription.nextBillingDate) ?? Date()
            _name = State(initialValue: subscription.name)
            _amount = State(initialValue: initialAmount)
            _currency = State(initialValue: subscription.currency)
            _billingPeriod = State(initialValue: subscription.billingPeriod)
            _category = State(initialValue: subscription.category ?? "")
            _hasNextBillingDate = State(initialValue: subscription.nextBillingDate != nil)
            _nextBillingDate = State(initialValue: initialDate)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название", text: $name)
                    TextField("Сумма", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Валюта", selection: $currency) {
                        ForEach(["RUB", "USD", "EUR"], id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    Picker("Период", selection: $billingPeriod) {
                        ForEach(periodOptions, id: \.value) { option in
                            Text(option.label).tag(option.value)
                        }
                    }
                    TextField("Категория", text: $category)
                }

                Section("Следующее списание") {
                    Toggle("Указать дату", isOn: $hasNextBillingDate)
                    if hasNextBillingDate {
                        DatePicker(
                            "Дата",
                            selection: $nextBillingDate,
                            displayedComponents: .date
                        )
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(mode.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Сохранение..." : "Сохранить") {
                        Task { await submit() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
}

private extension SubscriptionFormView {
    struct PeriodOption {
        let value: String
        let label: String
    }

    var periodOptions: [PeriodOption] {
        [
            PeriodOption(value: "monthly", label: "Ежемесячно"),
            PeriodOption(value: "yearly", label: "Ежегодно"),
            PeriodOption(value: "weekly", label: "Еженедельно")
        ]
    }

    func submit() async {
        errorMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Введите название подписки."
            return
        }
        guard let amountValue = Self.parseAmount(amount), amountValue > 0, amountValue.isFinite else {
            errorMessage = "Введите корректную сумму."
            return
        }

        isSaving = true
        let payload = SubscriptionPayload(
            name: trimmedName,
            amount: amountValue,
            currency: currency,
            billingPeriod: billingPeriod,
            category: category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : category,
            nextBillingDate: hasNextBillingDate ? nextBillingDate : nil
        )

        do {
            try await onSubmit(payload)
            isSaving = false
            dismiss()
        } catch let apiError as APIError {
            isSaving = false
            errorMessage = apiError.message
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }

    static func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    static func parseAmount(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        let allowed = CharacterSet(charactersIn: "0123456789.,")
        let filteredScalars = trimmed.unicodeScalars.filter { allowed.contains($0) }
        let filtered = String(String.UnicodeScalarView(filteredScalars))
        if filtered.isEmpty { return nil }

        let lastSeparatorIndex = filtered.lastIndex(where: { $0 == "." || $0 == "," })
        var normalized = filtered
        if let idx = lastSeparatorIndex {
            let intPart = filtered[..<idx]
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: "")
            let fracPart = filtered[filtered.index(after: idx)...]
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: "")
            normalized = intPart + "." + fracPart
        } else {
            normalized = filtered
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: "")
        }

        if let value = Double(normalized) {
            return value
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter.number(from: trimmed)?.doubleValue
    }
}
