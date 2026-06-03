import Cocoa

// Stubs for XKey app-layer dependencies.
// These replace types that exist in the XKey app target but not in an isolated
// Swift Package. Sensible no-op defaults allow the engine to compile and run.

// MARK: - AppBehaviorDetector

class AppBehaviorDetector {
    static let shared = AppBehaviorDetector()
    private init() {}
    func isInBrowserAddressBar() -> Bool { false }
}

// MARK: - SharedSettings

class SharedSettings {
    static let shared = SharedSettings()
    private init() {}

    // Return true so engine's own vCheckSpelling remains the effective control.
    var spellCheckEnabled: Bool { true }
    var modernStyle: Bool { true }
    var restoreIfWrongSpelling: Bool { true }
    var instantRestoreOnWrongSpelling: Bool { true }

    func isWordInUserDictionary(_ word: String) -> Bool { false }

    func setSmartSwitchData(_ data: Data) {}
    func getSmartSwitchData() -> Data? { nil }

    func setInputSourceConfig(_ data: Data) {}
    func getInputSourceConfig() -> Data? { nil }
}

// MARK: - TranslationLanguage (Preferences.swift)

struct TranslationLanguage {
    var code: String
    static func find(byCode code: String) -> TranslationLanguage {
        TranslationLanguage(code: code)
    }
}

// MARK: - AXHelper (VNEngine.swift accessibility logging)

class AXHelper {
    static func getElement(_ element: AXUIElement?, attribute: String) -> AXUIElement? { nil }
    static func getString(_ element: AXUIElement, attribute: String) -> String? { nil }
    static func getRange(_ element: AXUIElement, attribute: String) -> CFRange? { nil }
}

// MARK: - DebugLogger (VNDictionaryManager.swift)

class DebugLogger {
    static let shared = DebugLogger()
    private init() {}
    func log(_ message: String) {}
}

// MARK: - KeyCodeToCharacter (MacroManager.swift)

class KeyCodeToCharacter {
    static func qwertyCharacter(keyCode: UInt16, withShift: Bool) -> Character? {
        let mapping: [UInt16: (Character, Character)] = [
            0x00: ("a", "A"), 0x01: ("s", "S"), 0x02: ("d", "D"), 0x03: ("f", "F"),
            0x04: ("h", "H"), 0x05: ("g", "G"), 0x06: ("z", "Z"), 0x07: ("x", "X"),
            0x08: ("c", "C"), 0x09: ("v", "V"), 0x0B: ("b", "B"), 0x0C: ("q", "Q"),
            0x0D: ("w", "W"), 0x0E: ("e", "E"), 0x0F: ("r", "R"), 0x10: ("y", "Y"),
            0x11: ("t", "T"), 0x12: ("1", "!"), 0x13: ("2", "@"), 0x14: ("3", "#"),
            0x15: ("4", "$"), 0x16: ("6", "^"), 0x17: ("5", "%"), 0x18: ("=", "+"),
            0x19: ("9", "("), 0x1A: ("7", "&"), 0x1B: ("-", "_"), 0x1C: ("8", "*"),
            0x1D: ("0", ")"), 0x1E: ("]", "}"), 0x1F: ("o", "O"), 0x20: ("u", "U"),
            0x21: ("[", "{"), 0x22: ("i", "I"), 0x23: ("p", "P"), 0x25: ("l", "L"),
            0x26: ("j", "J"), 0x27: ("'", "\""), 0x28: ("k", "K"), 0x29: (";", ":"),
            0x2A: ("\\", "|"), 0x2B: (",", "<"), 0x2C: ("/", "?"), 0x2D: ("n", "N"),
            0x2E: ("m", "M"), 0x2F: (".", ">"), 0x31: (" ", " "), 0x32: ("`", "~"),
        ]
        guard let pair = mapping[keyCode] else { return nil }
        return withShift ? pair.1 : pair.0
    }
}
