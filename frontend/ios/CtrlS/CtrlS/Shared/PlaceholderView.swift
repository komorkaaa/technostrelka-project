import SwiftUI

struct PlaceholderView: View {
    let title: String
    let message: String

    init(title: String, message: String = "Экран будет реализован в следующей ветке.") {
        self.title = title
        self.message = message
    }

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Text(title)
                .font(DS.Typography.headline)
            Text(message)
                .font(DS.Typography.body)
                .foregroundStyle(DS.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DS.Spacing.lg)
    }
}

#Preview {
    PlaceholderView(title: "Заглушка")
}
