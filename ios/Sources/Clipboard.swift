import UIKit
import HumanizeShared

enum MobileClipboard {
    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }

    static var currentString: String? {
        UIPasteboard.general.string
    }
}

/// Platform-specific clipboard provider for iOS.
struct IOSClipboardProvider: ClipboardProvider {
    @MainActor func copy(_ text: String) {
        MobileClipboard.copy(text)
    }

    @MainActor var currentString: String? {
        MobileClipboard.currentString
    }
}
