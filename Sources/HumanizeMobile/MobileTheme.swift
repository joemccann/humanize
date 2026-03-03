import SwiftUI
import UIKit

// MARK: - Adaptive design tokens (iOS)

enum MobileTheme {
    static let bg1 = Color(uiColor: adaptive(
        light: UIColor(red: 0.878, green: 0.949, blue: 0.996, alpha: 1),
        dark: UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
    ))
    static let bg2 = Color(uiColor: adaptive(
        light: UIColor(white: 1, alpha: 1),
        dark: UIColor(red: 0.08, green: 0.11, blue: 0.18, alpha: 1)
    ))
    static let bg3 = Color(uiColor: adaptive(
        light: UIColor(red: 0.729, green: 0.902, blue: 0.992, alpha: 0.5),
        dark: UIColor(red: 0.07, green: 0.10, blue: 0.17, alpha: 1)
    ))
    static let cardBg = Color(uiColor: adaptive(
        light: UIColor(white: 1, alpha: 0.85),
        dark: UIColor(red: 0.12, green: 0.15, blue: 0.22, alpha: 0.7)
    ))
    static let cardBorder = Color(uiColor: adaptive(
        light: UIColor(white: 1, alpha: 0.6),
        dark: UIColor(white: 1, alpha: 0.1)
    ))
    static let cardRing = Color(uiColor: adaptive(
        light: UIColor(red: 0.055, green: 0.647, blue: 0.914, alpha: 0.1),
        dark: UIColor(white: 1, alpha: 0.08)
    ))
    static let pillBg = Color(uiColor: adaptive(
        light: UIColor(white: 1, alpha: 0.7),
        dark: UIColor(red: 0.14, green: 0.17, blue: 0.24, alpha: 0.6)
    ))
    static let pillBorder = Color(uiColor: adaptive(
        light: UIColor(white: 0.5, alpha: 0.2),
        dark: UIColor(white: 1, alpha: 0.1)
    ))
    static let textPrimary = Color(uiColor: adaptive(
        light: UIColor(red: 0.057, green: 0.09, blue: 0.165, alpha: 1),
        dark: UIColor(red: 0.91, green: 0.92, blue: 0.94, alpha: 1)
    ))
    static let textSecondary = Color(uiColor: adaptive(
        light: UIColor(red: 0.392, green: 0.455, blue: 0.545, alpha: 1),
        dark: UIColor(red: 0.58, green: 0.635, blue: 0.706, alpha: 1)
    ))
    static let textTertiary = Color(uiColor: adaptive(
        light: UIColor(red: 0.58, green: 0.635, blue: 0.706, alpha: 1),
        dark: UIColor(red: 0.45, green: 0.50, blue: 0.57, alpha: 1)
    ))
    static let sky100 = Color(uiColor: adaptive(
        light: UIColor(red: 0.878, green: 0.949, blue: 0.996, alpha: 1),
        dark: UIColor(red: 0.055, green: 0.647, blue: 0.914, alpha: 0.15)
    ))
    static let sky200 = Color(uiColor: adaptive(
        light: UIColor(red: 0.729, green: 0.902, blue: 0.992, alpha: 1),
        dark: UIColor(red: 0.055, green: 0.647, blue: 0.914, alpha: 0.2)
    ))
    static let sky500 = Color(red: 0.055, green: 0.647, blue: 0.914)
    static let sky600 = Color(uiColor: adaptive(
        light: UIColor(red: 0.008, green: 0.518, blue: 0.78, alpha: 1),
        dark: UIColor(red: 0.22, green: 0.67, blue: 0.95, alpha: 1)
    ))
    static let sky700 = Color(uiColor: adaptive(
        light: UIColor(red: 0.012, green: 0.412, blue: 0.624, alpha: 1),
        dark: UIColor(red: 0.55, green: 0.82, blue: 0.97, alpha: 1)
    ))
    static let toneInactive = Color(uiColor: adaptive(
        light: UIColor(red: 0.2, green: 0.255, blue: 0.333, alpha: 1),
        dark: UIColor(red: 0.78, green: 0.80, blue: 0.84, alpha: 1)
    ))

    private static func adaptive(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}
