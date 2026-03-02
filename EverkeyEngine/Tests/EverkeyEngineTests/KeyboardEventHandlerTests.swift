import XCTest
@testable import EverkeyEngine

// MARK: - Test Doubles

class SpyInjector: TextInjecting {
    var lastBackspaceCount: Int?
    var lastText: String?
    var callCount = 0
    private(set) var screenContent = ""

    func inject(backspaceCount: Int, text: String) {
        lastBackspaceCount = backspaceCount
        lastText = text
        callCount += 1
        let deleteCount = min(backspaceCount, screenContent.count)
        screenContent.removeLast(deleteCount)
        screenContent += text
    }

    func passThrough(_ char: Character) {
        screenContent += String(char)
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

        // Inactive: "a" + "s" → literal pass-through, no injection
        injector.callCount = 0
        type("a")
        type("s")

        XCTAssertEqual(injector.callCount, 0)
        XCTAssertEqual(injector.screenContent, "as")
    }

    // MARK: - Pass-through Cases

    func test_keyRepeat_passesThrough() {
        let event = KeyEvent(type: .keyDown, keyCode: 0, flags: [], isRepeat: true, character: "a")
        let suppress = handler.handleEvent(event)
        XCTAssertFalse(suppress)
        XCTAssertEqual(injector.callCount, 0)
    }

    func test_arrowKey_resetsEngine_passesThrough() {
        type("v")
        type("i")

        // Left arrow (0x7B)
        let suppress = handler.handleEvent(KeyEvent(type: .keyDown, keyCode: 0x7B))
        XCTAssertFalse(suppress)

        // Engine reset — "s" passes through as literal (no tone on "i")
        injector.callCount = 0
        type("s")
        XCTAssertEqual(injector.callCount, 0)
    }

    func test_commandCombo_resetsEngine_passesThrough() {
        type("v")
        type("i")

        let event = KeyEvent(type: .keyDown, keyCode: 0x08, flags: .command, character: "c")
        let suppress = handler.handleEvent(event)
        XCTAssertFalse(suppress)

        // Engine reset — "s" passes through as literal
        injector.callCount = 0
        type("s")
        XCTAssertEqual(injector.callCount, 0)
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
        type("v")
        type("i")

        let suppress = handler.handleEvent(KeyEvent(type: .mouseDown))
        XCTAssertFalse(suppress)

        // Engine reset — "s" passes through as literal
        injector.callCount = 0
        type("s")
        XCTAssertEqual(injector.callCount, 0)
    }

    func test_otherEvent_passesThrough() {
        let suppress = handler.handleEvent(KeyEvent(type: .other))
        XCTAssertFalse(suppress)
    }

    // MARK: - Vietnamese Input

    func test_plainLetter_passesThrough_withoutInjection() {
        // Pure append (bs:0, text == typed char) → pass through original event
        let suppress = handler.handleEvent(keyDown("b"))
        XCTAssertFalse(suppress)
        XCTAssertEqual(injector.callCount, 0)
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
        type("V", shift: true)
        type("i")
        type("e")
        type("e")  // circumflex ê
        type("j")  // nặng
        type("t")

        XCTAssertEqual(injector.screenContent, "Việt")
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
        type("v")
        type("i")

        let enterEvent = KeyEvent(type: .keyDown, keyCode: 0x24, character: "\n")
        let suppress = handler.handleEvent(enterEvent)
        XCTAssertFalse(suppress, "Enter must pass through as real key event")

        // Engine reset — "s" passes through as literal
        injector.callCount = 0
        type("s")
        XCTAssertEqual(injector.callCount, 0)
    }

    func test_tabKey_resetsEngine_passesThrough() {
        type("v")
        type("i")

        let tabEvent = KeyEvent(type: .keyDown, keyCode: 0x30, character: "\t")
        let suppress = handler.handleEvent(tabEvent)
        XCTAssertFalse(suppress, "Tab must pass through as real key event")

        // Engine reset — "s" passes through as literal
        injector.callCount = 0
        type("s")
        XCTAssertEqual(injector.callCount, 0)
    }

    func test_escapeKey_resetsEngine_passesThrough() {
        type("v")
        type("i")

        let escEvent = KeyEvent(type: .keyDown, keyCode: 0x35)
        let suppress = handler.handleEvent(escEvent)
        XCTAssertFalse(suppress, "Escape must pass through as real key event")

        // Engine reset — "s" passes through as literal
        injector.callCount = 0
        type("s")
        XCTAssertEqual(injector.callCount, 0)
    }

    // MARK: - resetEngine

    func test_resetEngine_clearsBuffer() {
        type("v")
        type("i")

        handler.resetEngine()

        // After reset, "s" passes through as literal (not tone on "i")
        injector.callCount = 0
        type("s")
        XCTAssertEqual(injector.callCount, 0)
    }

    // MARK: - English Detection Toggle

    func test_noDetector_englishDetectionIsDisabled() {
        let handler = KeyboardEventHandler(injector: SpyInjector())
        XCTAssertFalse(handler.isEnglishDetectionEnabled)
    }

    func test_withDetector_englishDetectionIsEnabled() {
        let handler = KeyboardEventHandler(
            injector: SpyInjector(),
            detector: ConsonantClusterDetector()
        )
        XCTAssertTrue(handler.isEnglishDetectionEnabled)
    }

    func test_detectionEnabled_frost_skipsTelex() {
        let spy = SpyInjector()
        let handler = KeyboardEventHandler(
            injector: spy,
            detector: ConsonantClusterDetector()
        )
        typeInto(handler, spy: spy, keys: "frost")
        XCTAssertEqual(spy.screenContent, "frost")
    }

    func test_detectionDisabled_frost_appliesTelex() {
        let spy = SpyInjector()
        let handler = KeyboardEventHandler(
            injector: spy,
            detector: ConsonantClusterDetector()
        )
        handler.setEnglishDetection(enabled: false)
        XCTAssertFalse(handler.isEnglishDetectionEnabled)

        typeInto(handler, spy: spy, keys: "frost")
        XCTAssertEqual(spy.screenContent, "fr\u{00F3}t") // fróst → s applies sắc
    }

    func test_reenableDetection_restoresBehavior() {
        let spy = SpyInjector()
        let handler = KeyboardEventHandler(
            injector: spy,
            detector: ConsonantClusterDetector()
        )
        handler.setEnglishDetection(enabled: false)
        handler.setEnglishDetection(enabled: true)
        handler.resetEngine()

        typeInto(handler, spy: spy, keys: "frost")
        XCTAssertEqual(spy.screenContent, "frost")
    }

    // MARK: - Helpers

    @discardableResult
    private func type(_ char: Character, shift: Bool = false) -> Bool {
        let event = keyDown(char, shift: shift)
        let suppress = handler.handleEvent(event)
        if !suppress, let c = event.character {
            injector.passThrough(c)
        }
        return suppress
    }

    private func typeInto(_ handler: KeyboardEventHandler, spy: SpyInjector, keys: String) {
        for c in keys {
            let event = keyDown(c)
            let suppress = handler.handleEvent(event)
            if !suppress, let ch = event.character {
                spy.passThrough(ch)
            }
        }
    }

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
