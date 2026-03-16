import Foundation

/// Cross-platform clipboard abstraction.
///
/// Each platform provides its own implementation using the native pasteboard API.
/// This protocol enables shared code to copy text without `#if os()` guards.
public protocol ClipboardProvider: Sendable {
    @MainActor func copy(_ text: String)
    @MainActor var currentString: String? { get }
}
