import AppKit

enum InjectionMode {
    case fast
    case slowTerminal   // Terminal: 8ms BS, 25ms wait, 8ms text, one-by-one
    case slowIDE        // JetBrains: 12ms BS, 30ms wait, 12ms text, one-by-one
    case addressBar     // Browser address bars: U+202F workaround

    var delays: (backspace: UInt32, wait: UInt32, text: UInt32) {
        switch self {
        case .fast, .addressBar: return (0, 0, 0)
        case .slowTerminal:      return (8_000, 25_000, 8_000)
        case .slowIDE:           return (12_000, 30_000, 12_000)
        }
    }

    var usesOneByOne: Bool {
        switch self {
        case .slowTerminal, .slowIDE: return true
        default: return false
        }
    }
}

class AppBehaviorDetector {
    static let shared = AppBehaviorDetector()
    private init() {}

    private var currentBundleID: String?

    private static let terminalBundleIDs: Set<String> = [
        "com.apple.Terminal", "io.alacritty", "com.mitchellh.ghostty",
        "net.kovidgoyal.kitty", "com.github.wez.wezterm", "com.raphaelamorim.rio",
        "com.googlecode.iterm2", "dev.warp.Warp-Stable", "co.zeit.hyper",
        "org.tabby", "com.termius-dmg.mac", "com.cmuxterm.app",
    ]

    func updateApp(bundleID: String?) {
        currentBundleID = bundleID
    }

    func detectMode() -> InjectionMode {
        if isInAddressBar() { return .addressBar }
        guard let bundleID = currentBundleID else { return .fast }
        if Self.terminalBundleIDs.contains(bundleID) { return .slowTerminal }
        if bundleID.hasPrefix("com.jetbrains") { return .slowIDE }
        return .fast
    }

    // MARK: - AX Address Bar Detection

    private func isInAddressBar() -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &ref) == .success,
              let ref else { return false }
        let element = ref as! AXUIElement

        if let id = axString(element, kAXIdentifierAttribute as String) {
            // Safari, Firefox / Zen
            if id == "WEB_BROWSER_ADDRESS_AND_SEARCH_FIELD" || id == "urlbar-input" { return true }
        }

        if let desc = axString(element, kAXDescriptionAttribute as String) {
            // Chrome, Edge, Brave, Opera
            if desc == "Address and search bar" || desc == "Address field" { return true }
        }

        return false
    }

    private func axString(_ element: AXUIElement, _ attribute: String) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success else { return nil }
        return ref as? String
    }
}
