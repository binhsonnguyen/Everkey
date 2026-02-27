import CoreGraphics
import EverkeyEngine

class KeyboardEventHandler {
    private var engine = Engine()
    private let injector = CharacterInjector()
    private(set) var isVietnamese = true
    var onToggle: ((Bool) -> Void)?

    private let cursorMovementKeys: Set<Int64> = [
        0x7B, // Left Arrow
        0x7C, // Right Arrow
        0x7E, // Up Arrow
        0x7D, // Down Arrow
        0x73, // Home
        0x77, // End
        0x74, // Page Up
        0x79, // Page Down
    ]

    func resetEngine() {
        engine.reset()
    }

    func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .keyDown:
            return handleKeyDown(proxy: proxy, event: event)
        case .leftMouseDown, .rightMouseDown:
            engine.reset()
            return Unmanaged.passUnretained(event)
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    // MARK: - Key Down

    private func handleKeyDown(proxy: CGEventTapProxy, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        // Toggle hotkey: Ctrl+Space
        let spaceKeyCode: Int64 = 0x31
        if keyCode == spaceKeyCode && flags.contains(.maskControl) {
            isVietnamese.toggle()
            engine.setActive(isVietnamese)
            onToggle?(isVietnamese)
            return nil  // suppress the hotkey event
        }

        // Key repeat → pass through
        if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
            return Unmanaged.passUnretained(event)
        }

        // Cursor movement → reset engine, pass through
        if cursorMovementKeys.contains(keyCode) {
            engine.reset()
            return Unmanaged.passUnretained(event)
        }

        // Modifier combo (Cmd/Ctrl/Alt + key) → reset engine, pass through
        let modifierMask: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate]
        if !flags.intersection(modifierMask).isEmpty {
            engine.reset()
            return Unmanaged.passUnretained(event)
        }

        // Extract character from event
        guard let character = extractCharacter(from: event) else {
            return Unmanaged.passUnretained(event)
        }

        let shift = flags.contains(.maskShift) || flags.contains(.maskAlphaShift)

        // Process through engine
        let output = engine.processKey(key: character, shift: shift)

        // If engine produced output that changes text, inject it
        if output.backspaceCount > 0 || !output.committedText.isEmpty {
            injector.inject(backspaceCount: output.backspaceCount, text: output.committedText, proxy: proxy)
            return nil  // suppress original event
        }

        return Unmanaged.passUnretained(event)
    }

    // MARK: - Character Extraction

    private func extractCharacter(from event: CGEvent) -> Character? {
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
