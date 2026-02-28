import CoreGraphics
import EverkeyEngine

struct CGEventAdapter {
    static func adapt(event: CGEvent, type: CGEventType) -> KeyEvent {
        let eventType = mapEventType(type)
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = mapFlags(event.flags)
        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        let character = extractCharacter(from: event)

        return KeyEvent(
            type: eventType,
            keyCode: keyCode,
            flags: flags,
            isRepeat: isRepeat,
            character: character
        )
    }

    // MARK: - Mapping

    private static func mapEventType(_ type: CGEventType) -> KeyEventType {
        switch type {
        case .keyDown:
            return .keyDown
        case .leftMouseDown, .rightMouseDown:
            return .mouseDown
        default:
            return .other
        }
    }

    private static func mapFlags(_ cgFlags: CGEventFlags) -> KeyEventFlags {
        var flags = KeyEventFlags()
        if cgFlags.contains(.maskShift)      { flags.insert(.shift) }
        if cgFlags.contains(.maskAlphaShift) { flags.insert(.capsLock) }
        if cgFlags.contains(.maskControl)    { flags.insert(.control) }
        if cgFlags.contains(.maskAlternate)  { flags.insert(.option) }
        if cgFlags.contains(.maskCommand)    { flags.insert(.command) }
        return flags
    }

    // MARK: - Character Extraction

    private static func extractCharacter(from event: CGEvent) -> Character? {
        var length = 0
        event.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
        guard length > 0 else { return nil }

        var chars = [UniChar](repeating: 0, count: length)
        event.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &chars)
        guard length > 0 else { return nil }

        let str = String(utf16CodeUnits: chars, count: length)
        return str.first
    }
}
