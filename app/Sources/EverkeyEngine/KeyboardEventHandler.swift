public class KeyboardEventHandler {
    private var engine = Engine()
    private let injector: TextInjecting
    public private(set) var isVietnamese = true
    public var onToggle: ((Bool) -> Void)?

    private let passthroughKeys: Set<Int64> = [
        0x24, // Enter (Return)
        0x30, // Tab
        0x35, // Escape
    ]

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

    public init(injector: TextInjecting) {
        self.injector = injector
    }

    public func resetEngine() {
        engine.reset()
    }

    /// Returns true if the event should be suppressed, false to pass through.
    public func handleEvent(_ event: KeyEvent) -> Bool {
        switch event.type {
        case .keyDown:
            return handleKeyDown(event)
        case .mouseDown:
            engine.reset()
            return false
        case .other:
            return false
        }
    }

    // MARK: - Key Down

    private func handleKeyDown(_ event: KeyEvent) -> Bool {
        let keyCode = event.keyCode

        // Toggle hotkey: Ctrl+Space
        let spaceKeyCode: Int64 = 0x31
        if keyCode == spaceKeyCode && event.flags.contains(.control) {
            isVietnamese.toggle()
            engine.setActive(isVietnamese)
            onToggle?(isVietnamese)
            return true
        }

        // Key repeat → pass through
        if event.isRepeat { return false }

        // Pass-through keys (Enter, Tab, Escape) → reset engine, pass through real event
        if passthroughKeys.contains(keyCode) {
            engine.reset()
            return false
        }

        // Cursor movement → reset engine, pass through
        if cursorMovementKeys.contains(keyCode) {
            engine.reset()
            return false
        }

        // Modifier combo (Cmd/Ctrl/Alt + key) → reset engine, pass through
        let modifierMask: KeyEventFlags = [.command, .control, .option]
        if !event.flags.intersection(modifierMask).isEmpty {
            engine.reset()
            return false
        }

        // Extract character
        guard let character = event.character else { return false }

        let shift = event.flags.contains(.shift) || event.flags.contains(.capsLock)

        // Process through engine
        let output = engine.processKey(key: character, shift: shift)

        // If engine produced output that changes text, inject it
        if output.backspaceCount > 0 || !output.committedText.isEmpty {
            injector.inject(backspaceCount: output.backspaceCount, text: output.committedText)
            return true
        }

        return false
    }
}
