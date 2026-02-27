// MARK: - Event Types

public enum KeyEventType {
    case keyDown
    case mouseDown
    case other
}

public struct KeyEventFlags: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let shift    = KeyEventFlags(rawValue: 1 << 0)
    public static let control  = KeyEventFlags(rawValue: 1 << 1)
    public static let option   = KeyEventFlags(rawValue: 1 << 2)
    public static let command  = KeyEventFlags(rawValue: 1 << 3)
    public static let capsLock = KeyEventFlags(rawValue: 1 << 4)
}

public struct KeyEvent {
    public let type: KeyEventType
    public let keyCode: Int64
    public let flags: KeyEventFlags
    public let isRepeat: Bool
    public let character: Character?

    public init(
        type: KeyEventType,
        keyCode: Int64 = 0,
        flags: KeyEventFlags = [],
        isRepeat: Bool = false,
        character: Character? = nil
    ) {
        self.type = type
        self.keyCode = keyCode
        self.flags = flags
        self.isRepeat = isRepeat
        self.character = character
    }
}

// MARK: - Text Injection Protocol

public protocol TextInjecting {
    func inject(backspaceCount: Int, text: String)
}
