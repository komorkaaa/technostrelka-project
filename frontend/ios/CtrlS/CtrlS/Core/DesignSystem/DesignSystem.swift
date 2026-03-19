import SwiftUI

enum DS {
    enum ColorToken {
        static let accent = Color(red: 0.63, green: 0.23, blue: 0.89)
        static let accentDark = Color(red: 0.47, green: 0.14, blue: 0.76)
        static let accentPink = Color(red: 0.91, green: 0.08, blue: 0.54)
        static let textPrimary = Color(red: 0.12, green: 0.12, blue: 0.14)
        static let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.5)
        static let cardBackground = Color.white
        static let screenBackground = Color(red: 0.98, green: 0.98, blue: 0.99)
        static let chipBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
        static let border = Color(red: 0.89, green: 0.9, blue: 0.94)
        static let softPurple = Color(red: 0.95, green: 0.91, blue: 1.0)
        static let softBlue = Color(red: 0.91, green: 0.95, blue: 1.0)
        static let softGreen = Color(red: 0.9, green: 0.97, blue: 0.92)
        static let softOrange = Color(red: 1.0, green: 0.95, blue: 0.89)
        static let softRed = Color(red: 1.0, green: 0.92, blue: 0.92)
        static let success = Color(red: 0.1, green: 0.66, blue: 0.34)
        static let warning = Color(red: 1.0, green: 0.47, blue: 0.09)
        static let infoBlue = Color(red: 0.23, green: 0.43, blue: 0.9)
        static let cardShadow = Color.black.opacity(0.03)
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
        static let xl: CGFloat = 28
    }

    enum Typography {
        static let title = Font.system(size: 20, weight: .bold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let subheadline = Font.system(size: 13, weight: .semibold, design: .default)
        static let body = Font.system(size: 15, weight: .regular, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let captionBold = Font.system(size: 11, weight: .semibold, design: .default)
    }
}
