import SwiftUI
import UIKit

/// Savora design tokens. Every color resolves per trait collection, so views
/// never branch on light/dark themselves.
enum Palette {
    static let background = Color(light: 0xFFF7F2, dark: 0x130E17)
    static let surface = Color(light: 0xFFFFFF, dark: 0x1E1724)
    static let surfaceRaised = Color(light: 0xFFEEE5, dark: 0x2A2131)
    static let stroke = Color(light: 0xF1DED4, dark: 0x332A3A)
    static let textPrimary = Color(light: 0x22141F, dark: 0xFBF3EE)
    static let textSecondary = Color(light: 0x6E5A66, dark: 0xBBAAB6)
    static let textTertiary = Color(light: 0xA8949E, dark: 0x7D6D79)
    static let primary = Color(light: 0xFF5A47, dark: 0xFF6B57)
    static let star = Color(light: 0xFFB13D, dark: 0xFFC15C)
    static let danger = Color(light: 0xE5484D, dark: 0xFF6369)
    static let shadow = Color(light: 0x7A2E1F, dark: 0x000000, lightAlpha: 0.12, darkAlpha: 0.4)
    static let glowWarm = Color(light: 0xFFB13D, dark: 0xFF8A3D, lightAlpha: 0.2, darkAlpha: 0.16)
    static let glowCool = Color(light: 0xFF4D6D, dark: 0x9B5CFF, lightAlpha: 0.15, darkAlpha: 0.18)

    static let brandGradient = LinearGradient(colors: [Color(hex: 0xFF8A3D), Color(hex: 0xFF4D6D)], startPoint: .leading, endPoint: .trailing)
}

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32

    /// Bottom inset that keeps scrollable content clear of the floating tab bar.
    static let tabBarClearance: CGFloat = 110
}

enum Radius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 20
    static let lg: CGFloat = 28
}

extension Font {
    /// Serif display face for headlines, the role Fraunces plays in the Flutter app.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(light: UInt32, dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: dark, alpha: darkAlpha)) : UIColor(Color(hex: light, alpha: lightAlpha))
        })
    }
}
