import XCTest
@testable import EverkeyEngine

/// A single test case: type `keys` into a fresh engine, expect `expected` as committed text.
struct TelexTestCase {
    let keys: String
    let expected: String
    let description: String
    let uppercaseFirst: Bool

    init(_ keys: String, _ expected: String, _ description: String, uppercaseFirst: Bool = false) {
        self.keys = keys
        self.expected = expected
        self.description = description
        self.uppercaseFirst = uppercaseFirst
    }
}

/// Type a key sequence into a fresh engine, return the accumulated screen text.
func typeSequence(_ keys: String, uppercaseFirst: Bool = false) -> String {
    var engine = Engine()
    var screen = ""
    for (i, c) in keys.enumerated() {
        let shift = (i == 0) && uppercaseFirst && c.isLetter
        let output = engine.processKey(key: c, shift: shift)
        screen.removeLast(min(output.backspaceCount, screen.count))
        screen += output.committedText
    }
    return screen
}

/// Type a key sequence into an existing engine, return the final output.
@discardableResult
func typeInto(_ engine: inout Engine, keys: String, shiftFirst: Bool = false) -> EngineOutput {
    var output = EngineOutput(backspaceCount: 0, committedText: "")
    for (i, c) in keys.enumerated() {
        let shift = (i == 0) && shiftFirst && c.isLetter
        output = engine.processKey(key: c, shift: shift)
    }
    return output
}

/// Type a key sequence into an existing engine, return the accumulated screen text.
/// Tracks incremental outputs (backspace + committed text) to reconstruct what appears on screen.
func screenText(_ engine: inout Engine, keys: String, shiftFirst: Bool = false) -> String {
    var screen = ""
    for (i, c) in keys.enumerated() {
        let shift = (i == 0) && shiftFirst && c.isLetter
        let output = engine.processKey(key: c, shift: shift)
        screen.removeLast(min(output.backspaceCount, screen.count))
        screen += output.committedText
    }
    return screen
}

/// Assert a batch of TelexTestCases. Fails with description on mismatch.
func assertTelex(_ cases: [TelexTestCase], file: StaticString = #file, line: UInt = #line) {
    for tc in cases {
        let actual = typeSequence(tc.keys, uppercaseFirst: tc.uppercaseFirst)
        XCTAssertEqual(actual, tc.expected, tc.description, file: file, line: line)
    }
}
