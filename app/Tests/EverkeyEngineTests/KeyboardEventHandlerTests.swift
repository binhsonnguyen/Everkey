import XCTest
@testable import EverkeyEngine

// MARK: - Test Doubles

class SpyInjector: TextInjecting {
    var lastBackspaceCount: Int?
    var lastText: String?
    var callCount = 0

    func inject(backspaceCount: Int, text: String) {
        lastBackspaceCount = backspaceCount
        lastText = text
        callCount += 1
    }
}

// MARK: - Tests

final class KeyboardEventHandlerTests: XCTestCase {

    private var injector: SpyInjector!
    private var handler: KeyboardEventHandler!

    override func setUp() {
        injector = SpyInjector()
        handler = KeyboardEventHandler(injector: injector)
    }

    // MARK: - Toggle (Ctrl+Space)

    func test_ctrlSpace_togglesVietnamese_andSuppresses() {
        XCTAssertTrue(handler.isVietnamese)

        let suppress = handler.handleEvent(ctrlSpace())
        XCTAssertTrue(suppress)
        XCTAssertFalse(handler.isVietnamese)

        let suppress2 = handler.handleEvent(ctrlSpace())
        XCTAssertTrue(suppress2)
        XCTAssertTrue(handler.isVietnamese)
    }

    func test_ctrlSpace_callsOnToggle() {
        var toggleValues: [Bool] = []
        handler.onToggle = { toggleValues.append($0) }

        _ = handler.handleEvent(ctrlSpace())
        _ = handler.handleEvent(ctrlSpace())

        XCTAssertEqual(toggleValues, [false, true])
    }

    func test_ctrlSpace_deactivatesEngine_producesLiterals() {
        // Toggle off
        _ = handler.handleEvent(ctrlSpace())

        // Inactive: "a" + "s" → literal "a" then literal "s" (no tone)
        injector.callCount = 0
        _ = handler.handleEvent(keyDown("a"))
        _ = handler.handleEvent(keyDown("s"))

        XCTAssertEqual(injector.lastText, "s")
        XCTAssertEqual(injector.lastBackspaceCount, 0)
    }

    // MARK: - Pass-through Cases

    func test_keyRepeat_passesThrough() {
        let event = KeyEvent(type: .keyDown, keyCode: 0, flags: [], isRepeat: true, character: "a")
        let suppress = handler.handleEvent(event)
        XCTAssertFalse(suppress)
        XCTAssertEqual(injector.callCount, 0)
    }

    func test_arrowKey_resetsEngine_passesThrough() {
        _ = handler.handleEvent(keyDown("v"))
        _ = handler.handleEvent(keyDown("i"))

        // Left arrow (0x7B)
        let suppress = handler.handleEvent(KeyEvent(type: .keyDown, keyCode: 0x7B))
        XCTAssertFalse(suppress)

        // Engine reset — "s" starts a fresh word, not tone on "i"
        injector.callCount = 0
        _ = handler.handleEvent(keyDown("s"))
        XCTAssertEqual(injector.lastText, "s")
        XCTAssertEqual(injector.lastBackspaceCount, 0)
    }

    func test_commandCombo_resetsEngine_passesThrough() {
        _ = handler.handleEvent(keyDown("v"))
        _ = handler.handleEvent(keyDown("i"))

        let event = KeyEvent(type: .keyDown, keyCode: 0x08, flags: .command, character: "c")
        let suppress = handler.handleEvent(event)
        XCTAssertFalse(suppress)

        // Engine reset — "s" starts fresh
        injector.callCount = 0
        _ = handler.handleEvent(keyDown("s"))
        XCTAssertEqual(injector.lastText, "s")
        XCTAssertEqual(injector.lastBackspaceCount, 0)
    }

    func test_altCombo_resetsEngine_passesThrough() {
        let event = KeyEvent(type: .keyDown, keyCode: 0, flags: .option, character: "a")
        let suppress = handler.handleEvent(event)
        XCTAssertFalse(suppress)
    }

    func test_noCharacter_passesThrough() {
        let event = KeyEvent(type: .keyDown, keyCode: 0x30, character: nil)
        let suppress = handler.handleEvent(event)
        XCTAssertFalse(suppress)
        XCTAssertEqual(injector.callCount, 0)
    }

    // MARK: - Event Routing

    func test_mouseDown_resetsEngine_passesThrough() {
        _ = handler.handleEvent(keyDown("v"))
        _ = handler.handleEvent(keyDown("i"))

        let suppress = handler.handleEvent(KeyEvent(type: .mouseDown))
        XCTAssertFalse(suppress)

        // Engine reset — "s" starts a fresh word
        injector.callCount = 0
        _ = handler.handleEvent(keyDown("s"))
        XCTAssertEqual(injector.lastText, "s")
        XCTAssertEqual(injector.lastBackspaceCount, 0)
    }

    func test_otherEvent_passesThrough() {
        let suppress = handler.handleEvent(KeyEvent(type: .other))
        XCTAssertFalse(suppress)
    }

    // MARK: - Vietnamese Input

    func test_plainLetter_injectsAndSuppresses() {
        let suppress = handler.handleEvent(keyDown("b"))
        XCTAssertTrue(suppress)
        XCTAssertEqual(injector.callCount, 1)
        XCTAssertEqual(injector.lastText, "b")
        XCTAssertEqual(injector.lastBackspaceCount, 0)
    }

    func test_toneOnVowel_injectsWithBackspace() {
        // "a" then "s" → "á"
        _ = handler.handleEvent(keyDown("a"))
        injector.callCount = 0

        let suppress = handler.handleEvent(keyDown("s"))
        XCTAssertTrue(suppress)
        XCTAssertEqual(injector.lastText, "á")
        XCTAssertEqual(injector.lastBackspaceCount, 1)
    }

    func test_vieejt_produces_Viet() {
        _ = handler.handleEvent(keyDown("V", shift: true))
        _ = handler.handleEvent(keyDown("i"))
        _ = handler.handleEvent(keyDown("e"))
        _ = handler.handleEvent(keyDown("e"))  // circumflex ê
        _ = handler.handleEvent(keyDown("j"))  // nặng
        _ = handler.handleEvent(keyDown("t"))

        XCTAssertEqual(injector.lastText, "Việt")
    }

    // MARK: - Shift / CapsLock

    func test_shiftFlag_producesUppercase() {
        _ = handler.handleEvent(keyDown("A", shift: true))
        _ = handler.handleEvent(keyDown("s"))

        XCTAssertEqual(injector.lastText, "Á")
    }

    func test_capsLockFlag_producesUppercase() {
        let event = KeyEvent(type: .keyDown, keyCode: 0, flags: .capsLock, character: "a")
        _ = handler.handleEvent(event)
        _ = handler.handleEvent(keyDown("s"))

        XCTAssertEqual(injector.lastText, "Á")
    }

    // MARK: - Pass-through Keys (Enter, Tab, Escape)

    func test_enterKey_resetsEngine_passesThrough() {
        _ = handler.handleEvent(keyDown("v"))
        _ = handler.handleEvent(keyDown("i"))

        let enterEvent = KeyEvent(type: .keyDown, keyCode: 0x24, character: "\n")
        let suppress = handler.handleEvent(enterEvent)
        XCTAssertFalse(suppress, "Enter must pass through as real key event")

        // Engine reset — "s" starts a fresh word, not tone on "i"
        injector.callCount = 0
        _ = handler.handleEvent(keyDown("s"))
        XCTAssertEqual(injector.lastText, "s")
        XCTAssertEqual(injector.lastBackspaceCount, 0)
    }

    func test_tabKey_resetsEngine_passesThrough() {
        _ = handler.handleEvent(keyDown("v"))
        _ = handler.handleEvent(keyDown("i"))

        let tabEvent = KeyEvent(type: .keyDown, keyCode: 0x30, character: "\t")
        let suppress = handler.handleEvent(tabEvent)
        XCTAssertFalse(suppress, "Tab must pass through as real key event")

        // Engine reset — "s" starts a fresh word, not tone on "i"
        injector.callCount = 0
        _ = handler.handleEvent(keyDown("s"))
        XCTAssertEqual(injector.lastText, "s")
        XCTAssertEqual(injector.lastBackspaceCount, 0)
    }

    // MARK: - resetEngine

    func test_resetEngine_clearsBuffer() {
        _ = handler.handleEvent(keyDown("v"))
        _ = handler.handleEvent(keyDown("i"))

        handler.resetEngine()

        // After reset, "s" starts a fresh word (not tone on "i")
        injector.callCount = 0
        _ = handler.handleEvent(keyDown("s"))
        XCTAssertEqual(injector.lastText, "s")
        XCTAssertEqual(injector.lastBackspaceCount, 0)
    }

    // MARK: - Helpers

    private func keyDown(_ char: Character, shift: Bool = false) -> KeyEvent {
        KeyEvent(
            type: .keyDown,
            keyCode: 0,
            flags: shift ? .shift : [],
            character: char
        )
    }

    private func ctrlSpace() -> KeyEvent {
        KeyEvent(type: .keyDown, keyCode: 0x31, flags: .control)
    }
}
