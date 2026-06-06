import CoreGraphics

public class KeyboardEventHandler {
    private let engine: VNEngine
    private let injector: TextInjecting
    public private(set) var isVietnamese = true
    public private(set) var isEnglishDetectionEnabled: Bool = true
    public var onToggle: ((Bool) -> Void)?

    private let passthroughKeys: Set<Int64> = [
        0x24, // Enter
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

    private static let backspaceKeyCode: Int64 = 0x33

    public init(injector: TextInjecting) {
        self.engine = VNEngine()
        self.injector = injector
        applyDefaultSettings()
    }

    private func applyDefaultSettings() {
        var settings = VNEngine.EngineSettings()
        settings.inputMethod = .telex
        settings.spellCheckEnabled = true
        settings.restoreIfWrongSpelling = true
        settings.quickTelexEnabled = false
        engine.updateSettings(settings)
    }

    public func performUndo() -> Bool {
        guard engine.canUndoTyping() else { return false }
        let result = engine.undoTyping()
        guard result.shouldConsume else { return false }
        let text = result.newCharacters.map { $0.unicode(codeTable: .unicode) }.joined()
        injector.inject(backspaceCount: result.backspaceCount, text: text)
        return true
    }

    public func setEnglishDetection(enabled: Bool) {
        isEnglishDetectionEnabled = enabled
        var settings = VNEngine.EngineSettings()
        settings.inputMethod = currentInputMethod
        settings.spellCheckEnabled = enabled
        engine.updateSettings(settings)
    }

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

    // MARK: - Private

    private var currentInputMethod: InputMethod {
        InputMethod(rawValue: engine.vInputType) ?? .telex
    }

    private func handleKeyDown(_ event: KeyEvent) -> Bool {
        let keyCode = event.keyCode

        // Toggle hotkey: Ctrl+Space
        if keyCode == 0x31 && event.flags.contains(.control) {
            isVietnamese.toggle()
            engine.vLanguage = isVietnamese ? 1 : 0
            if !isVietnamese { engine.reset() }
            onToggle?(isVietnamese)
            return true
        }

        if !isVietnamese { return false }

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

        if keyCode == Self.backspaceKeyCode {
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
