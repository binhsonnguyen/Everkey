import XCTest
@testable import EverkeyEngine

final class EngineAdapterTests: XCTestCase {

    // MARK: - Helpers

    class MockInjector: TextInjecting {
        var backspaces: Int = 0
        var injectedText: String = ""
        func inject(backspaceCount: Int, text: String) {
            backspaces = backspaceCount
            injectedText = text
        }
    }

    func makeHandler() -> (KeyboardEventHandler, MockInjector) {
        let injector = MockInjector()
        let handler = KeyboardEventHandler(injector: injector)
        return (handler, injector)
    }

    func keyDown(_ char: Character, keyCode: Int64, shift: Bool = false) -> KeyEvent {
        var flags: KeyEventFlags = []
        if shift { flags.insert(.shift) }
        return KeyEvent(type: .keyDown, keyCode: keyCode, flags: flags, character: char)
    }

    // MARK: - Basic typing

    func testPureLatinPassesThrough() {
        // Typing 'a' alone: engine buffers it, no transformation → handler returns false (pass through)
        let (handler, injector) = makeHandler()
        let suppress = handler.handleEvent(keyDown("a", keyCode: 0x00))
        XCTAssertFalse(suppress, "Plain 'a' should pass through")
        XCTAssertEqual(injector.injectedText, "")
    }

    func testTelex_dd_producesD_stroke() {
        // Telex: dd → đ
        // First 'd' buffers, second 'd' triggers transform
        let (handler, injector) = makeHandler()
        _ = handler.handleEvent(keyDown("d", keyCode: 0x02))
        let suppress = handler.handleEvent(keyDown("d", keyCode: 0x02))
        XCTAssertTrue(suppress, "Second 'd' in Telex should produce transform")
        XCTAssertEqual(injector.injectedText, "đ")
    }

    func testTelex_aa_producesA_circumflex() {
        // Telex: aa → â
        let (handler, injector) = makeHandler()
        _ = handler.handleEvent(keyDown("a", keyCode: 0x00))
        let suppress = handler.handleEvent(keyDown("a", keyCode: 0x00))
        XCTAssertTrue(suppress)
        XCTAssertEqual(injector.injectedText, "â")
    }

    func testWordBreakResetsEngine() {
        // After typing 'a', hitting space should pass through (no transformation)
        let (handler, _) = makeHandler()
        _ = handler.handleEvent(keyDown("a", keyCode: 0x00))
        let suppress = handler.handleEvent(keyDown(" ", keyCode: 0x31))
        XCTAssertFalse(suppress, "Space with plain 'a' buffer should pass through")
    }

    func testVietnameseToggle() {
        let (handler, _) = makeHandler()
        XCTAssertTrue(handler.isVietnamese)
        // Ctrl+Space toggles off
        let ctrlSpace = KeyEvent(type: .keyDown, keyCode: 0x31, flags: [.control], character: " ")
        _ = handler.handleEvent(ctrlSpace)
        XCTAssertFalse(handler.isVietnamese)
        // Toggle back on
        _ = handler.handleEvent(ctrlSpace)
        XCTAssertTrue(handler.isVietnamese)
    }

    func testMouseDownResetsEngine() {
        // Typing then mouse click: engine resets, no injection
        let (handler, injector) = makeHandler()
        _ = handler.handleEvent(keyDown("a", keyCode: 0x00))
        let mouseEvent = KeyEvent(type: .mouseDown)
        let suppress = handler.handleEvent(mouseEvent)
        XCTAssertFalse(suppress)
        XCTAssertEqual(injector.injectedText, "")
    }

    func testResetEngine() {
        let (handler, injector) = makeHandler()
        _ = handler.handleEvent(keyDown("a", keyCode: 0x00))
        handler.resetEngine()
        // After reset, second 'a' would not combine with first
        _ = handler.handleEvent(keyDown("a", keyCode: 0x00))
        XCTAssertEqual(injector.injectedText, "", "After reset, 'aa' should not produce â")
    }
}
