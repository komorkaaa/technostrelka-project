import SwiftUI

enum DS {
    enum ColorToken {
        static let accent = Color(red: 0.63, green: 0.23, blue: 0.89)
        static let accentDark = Color(red: 0.47, green: 0.14, blue: 0.76)
        static let textPrimary = Color(red: 0.12, green: 0.12, blue: 0.14)
        static let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.5)
        static let cardBackground = Color.white
        static let screenBackground = Color(red: 0.98, green: 0.98, blue: 0.99)
        static let chipBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
    }

    enum Typography {
        static let title = Font.system(size: 22, weight: .bold, design: .default)
        static let headline = Font.system(size: 18, weight: .semibold, design: .default)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
    }
}
