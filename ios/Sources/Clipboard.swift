import UIKit

enum MobileClipboard {
    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }

    static var currentString: String? {
        UIPasteboard.general.string
    }
}
