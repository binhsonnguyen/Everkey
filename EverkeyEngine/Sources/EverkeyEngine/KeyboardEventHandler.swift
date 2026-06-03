import CoreGraphics

public class KeyboardEventHandler {
    private let engine: VNEngine
    private let injector: TextInjecting
    public private(set) var isVietnamese = true
    public private(set) var isEnglishDetectionEnabled: Bool = true

    private static let passthroughKeys: Set<Int64> = [
        0x24, // Return
        0x30, // Tab
        0x35, // Escape
    ]
    private static let cursorMovementKeys: Set<Int64> = [
        0x7B, // Left Arrow
        0x7C, // Right Arrow
        0x7E, // Up Arrow
        0x7D, // Down Arrow
        0x73, // Home
        0x77, // End
        0x74, // Page Up
        0x79, // Page Down
    ]
    private static let backspaceKey: Int64 = 0x33

    public init(injector: TextInjecting) {
        self.engine = VNEngine()
        self.injector = injector
        applyDefaultSettings()
    }

    private func applyDefaultSettings() {
        engine.updateSettings(buildEngineSettings())
    }

    // MARK: - Public API

    public func setInputMethod(_ method: InputMethod) {
        engine.updateSettings(buildEngineSettings(inputMethod: method))
    }

    public func setEnglishDetection(enabled: Bool) {
        isEnglishDetectionEnabled = enabled
        engine.updateSettings(buildEngineSettings())
    }

    // MARK: - Private: canonical settings builder

    /// Single source of truth for engine settings.
    /// Always sets ALL fields so partial EngineSettings() defaults never bleed through.
    private func buildEngineSettings(inputMethod: InputMethod? = nil) -> VNEngine.EngineSettings {
        var s = VNEngine.EngineSettings()
        s.inputMethod = inputMethod ?? currentInputMethod
        s.spellCheckEnabled = false          // English detection off — keeps typing clean
        s.restoreIfWrongSpelling = false      // No auto-restore
        s.quickTelexEnabled = true            // cc→ch, dd→đ, etc.
        s.modernStyle = true                  // oà/uý (modern orthography)
        s.quickStartConsonantEnabled = false
        s.quickEndConsonantEnabled = false
        s.upperCaseFirstChar = false
        s.macroEnabled = false
        s.smartSwitchEnabled = false
        return s
    }

    public func resetEngine() {
        engine.reset()
    }

    public func setVietnameseMode(_ enabled: Bool) {
        guard enabled != isVietnamese else { return }
        isVietnamese = enabled
        engine.vLanguage = isVietnamese ? 1 : 0
        if !isVietnamese { engine.reset() }
    }

    /// Undo the last Vietnamese transformation (e.g. revert "việt" → "viet").
    /// Returns true if the event should be consumed.
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

        if event.isRepeat { return false }

        if Self.passthroughKeys.contains(keyCode) {
            engine.reset()
            return false
        }

        if Self.cursorMovementKeys.contains(keyCode) {
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
