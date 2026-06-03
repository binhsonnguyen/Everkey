import CoreGraphics

public class KeyboardEventHandler {
    private let engine: VNEngine
    private let injector: TextInjecting
    public private(set) var isVietnamese = true
    public var onToggle: ((Bool) -> Void)?

    private let passthroughKeys: Set<Int64> = [
        0x24, // Enter
        0x30, // Tab
        0x35, // Escape
    ]
    private let cursorMovementKeys: Set<Int64> = [
        0x7B, 0x7C, 0x7E, 0x7D, // Arrow keys
        0x73, 0x77, 0x74, 0x79, // Home/End/PgUp/PgDn
    ]
    private static let backspaceKey: Int64 = 0x33

    public init(injector: TextInjecting) {
        self.engine = VNEngine()
        self.injector = injector
        // Configure engine once at init. These settings worked in production.
        var s = VNEngine.EngineSettings()
        s.inputMethod = .telex
        s.spellCheckEnabled = true
        s.restoreIfWrongSpelling = true
        engine.updateSettings(s)
    }

    // MARK: - Public API

    public func resetEngine() {
        engine.reset()
    }

    public func setVietnameseMode(_ enabled: Bool) {
        guard enabled != isVietnamese else { return }
        isVietnamese = enabled
        engine.vLanguage = isVietnamese ? 1 : 0
        if !isVietnamese { engine.reset() }
        onToggle?(isVietnamese)
    }

    /// Undo the last Vietnamese transformation (revert "việt" → "viet").
    public func performUndo() -> Bool {
        guard engine.canUndoTyping() else { return false }
        let result = engine.undoTyping()
        guard result.shouldConsume else { return false }
        let text = result.newCharacters.map { $0.unicode(codeTable: .unicode) }.joined()
        injector.inject(backspaceCount: result.backspaceCount, text: text)
        return true
    }

    public func handleEvent(_ event: KeyEvent) -> Bool {
        switch event.type {
        case .keyDown:  return handleKeyDown(event)
        case .mouseDown: engine.reset(); return false
        case .other:    return false
        }
    }

    // MARK: - Private

    private var currentInputMethod: InputMethod {
        InputMethod(rawValue: engine.vInputType) ?? .telex
    }

    private func handleKeyDown(_ event: KeyEvent) -> Bool {
        let keyCode = event.keyCode

        // Ctrl+Space fallback toggle (active when EventTapManager doesn't consume it)
        if keyCode == 0x31 && event.flags.contains(.control) {
            setVietnameseMode(!isVietnamese)
            return true
        }

        if event.isRepeat { return false }

        if passthroughKeys.contains(keyCode) {
            engine.reset()
            return false
        }

        if cursorMovementKeys.contains(keyCode) {
            engine.resetWithCursorMoved()
            return false
        }

        let modifierMask: KeyEventFlags = [.command, .control, .option]
        if !event.flags.intersection(modifierMask).isEmpty {
            engine.reset()
            return false
        }

        if keyCode == Self.backspaceKey {
            return inject(engine.processBackspace())
        }

        guard let character = event.character else { return false }

        let isUppercase = event.flags.contains(.shift) != event.flags.contains(.capsLock)

        if VNEngine.isWordBreak(character: character, inputMethod: currentInputMethod) {
            return inject(engine.processWordBreak(character: character))
        }

        return inject(engine.processKey(
            character: character,
            keyCode: CGKeyCode(keyCode),
            isUppercase: isUppercase
        ))
    }

    private func inject(_ result: VNEngine.ProcessResult) -> Bool {
        guard result.shouldConsume else { return false }
        let text = result.newCharacters.map { $0.unicode(codeTable: .unicode) }.joined()
        injector.inject(backspaceCount: result.backspaceCount, text: text)
        return true
    }
}
