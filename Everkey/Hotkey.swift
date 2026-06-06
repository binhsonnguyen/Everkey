import Cocoa

struct Hotkey: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: ModifierFlags
    var isModifierOnly: Bool

    init(keyCode: UInt16, modifiers: ModifierFlags, isModifierOnly: Bool = false) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isModifierOnly = isModifierOnly
    }

    /// Ô phím tắt để trống (nút ✕ đặt keyCode 0, không modifier). Phải không bao giờ khớp phím
    /// thật — nếu không sẽ nuốt phím 'a' (vốn cũng có keyCode 0).
    var isUnset: Bool { keyCode == 0 && modifiers.isEmpty && !isModifierOnly }

    var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.function) { parts.append("Fn") }
        if modifiers.contains(.control)  { parts.append("⌃") }
        if modifiers.contains(.option)   { parts.append("⌥") }
        if modifiers.contains(.shift)    { parts.append("⇧") }
        if modifiers.contains(.command)  { parts.append("⌘") }

        if isModifierOnly { return parts.joined() }

        if let char = keyCodeToCharacter(keyCode) {
            parts.append(char)
        } else if keyCode != 0 {
            parts.append("?")
        }
        return parts.joined()
    }

    /// Ký tự cho NSMenuItem.keyEquivalent. Trả về "" nếu không thể hiển thị (modifier-only, unset).
    var menuKeyEquivalent: String {
        if isModifierOnly || isUnset { return "" }
        if keyCode == 0x31 { return " " }
        guard let char = keyCodeToCharacter(keyCode) else { return "" }
        return char.lowercased()
    }

    var menuModifierMask: NSEvent.ModifierFlags {
        var mask: NSEvent.ModifierFlags = []
        if modifiers.contains(.control)  { mask.insert(.control) }
        if modifiers.contains(.option)   { mask.insert(.option) }
        if modifiers.contains(.shift)    { mask.insert(.shift) }
        if modifiers.contains(.command)  { mask.insert(.command) }
        if modifiers.contains(.function) { mask.insert(.function) }
        return mask
    }

    func matches(event: CGEvent, type: CGEventType) -> Bool {
        if isModifierOnly { return false }
        guard type == .keyDown else { return false }
        let eventMods = ModifierFlags(from: event.flags)
        return UInt16(event.getIntegerValueField(.keyboardEventKeycode)) == keyCode
            && eventMods == modifiers
    }

    private func keyCodeToCharacter(_ keyCode: UInt16) -> String? {
        let map: [UInt16: String] = [
            0x00: "A", 0x0B: "B", 0x08: "C", 0x02: "D", 0x0E: "E",
            0x03: "F", 0x05: "G", 0x04: "H", 0x22: "I", 0x26: "J",
            0x28: "K", 0x25: "L", 0x2E: "M", 0x2D: "N", 0x1F: "O",
            0x23: "P", 0x0C: "Q", 0x0F: "R", 0x01: "S", 0x11: "T",
            0x20: "U", 0x09: "V", 0x0D: "W", 0x07: "X", 0x10: "Y",
            0x06: "Z", 0x31: "Space", 0x24: "Return", 0x35: "Esc",
        ]
        return map[keyCode]
    }
}

struct ModifierFlags: OptionSet, Codable {
    let rawValue: UInt

    static let control  = ModifierFlags(rawValue: 1 << 0)
    static let option   = ModifierFlags(rawValue: 1 << 1)
    static let shift    = ModifierFlags(rawValue: 1 << 2)
    static let command  = ModifierFlags(rawValue: 1 << 3)
    static let function = ModifierFlags(rawValue: 1 << 4)

    init(rawValue: UInt) { self.rawValue = rawValue }

    init(from eventFlags: CGEventFlags) {
        var flags: ModifierFlags = []
        if eventFlags.contains(.maskControl)   { flags.insert(.control) }
        if eventFlags.contains(.maskAlternate) { flags.insert(.option) }
        if eventFlags.contains(.maskShift)     { flags.insert(.shift) }
        if eventFlags.contains(.maskCommand)   { flags.insert(.command) }
        self = flags
    }

    init(from eventFlags: NSEvent.ModifierFlags) {
        var flags: ModifierFlags = []
        if eventFlags.contains(.control)  { flags.insert(.control) }
        if eventFlags.contains(.option)   { flags.insert(.option) }
        if eventFlags.contains(.shift)    { flags.insert(.shift) }
        if eventFlags.contains(.command)  { flags.insert(.command) }
        if eventFlags.contains(.function) { flags.insert(.function) }
        self = flags
    }
}
