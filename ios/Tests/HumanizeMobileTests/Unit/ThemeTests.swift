import Testing
import SwiftUI
@testable import HumanizeMobile

@Suite("MobileTheme")
struct ThemeTests {
    @Test("All 17 color tokens are accessible")
    func allColorTokensExist() {
        let colors: [Color] = [
            MobileTheme.bg1, MobileTheme.bg2, MobileTheme.bg3,
            MobileTheme.cardBg, MobileTheme.cardBorder, MobileTheme.cardRing,
            MobileTheme.pillBg, MobileTheme.pillBorder,
            MobileTheme.textPrimary, MobileTheme.textSecondary, MobileTheme.textTertiary,
            MobileTheme.sky100, MobileTheme.sky200, MobileTheme.sky500,
            MobileTheme.sky600, MobileTheme.sky700,
            MobileTheme.toneInactive,
        ]
        #expect(colors.count == 17)
    }

    @Test("sky500 is a constant non-nil color")
    func sky500Constant() {
        let color = MobileTheme.sky500
        #expect(color == Color(red: 0.055, green: 0.647, blue: 0.914))
    }
}
