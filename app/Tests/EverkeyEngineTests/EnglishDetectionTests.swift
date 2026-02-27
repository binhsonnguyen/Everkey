import XCTest
@testable import EverkeyEngine

// MARK: - A. ConsonantClusterDetector Tests

final class ConsonantClusterDetectorTests: XCTestCase {

    private let detector = ConsonantClusterDetector()

    func test_fr_isNonVietnamese() {
        let buffer = [VnChar(base: "f"), VnChar(base: "r")]
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
    }

    func test_all_valid_digraphs_areVietnamese() {
        let digraphs = ["ch", "gh", "gi", "kh", "ng", "nh", "ph", "qu", "th", "tr"]
        for digraph in digraphs {
            let buffer = digraph.map { VnChar(base: $0) }
            XCTAssertFalse(detector.isNonVietnamese(buffer: buffer),
                           "'\(digraph)' should be valid Vietnamese onset")
        }
    }

    func test_ngh_trigraph_isVietnamese() {
        let buffer = [VnChar(base: "n"), VnChar(base: "g"), VnChar(base: "h")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_thr_validPrefixButInvalidFullCluster_isNonVietnamese() {
        let buffer = [VnChar(base: "t"), VnChar(base: "h"), VnChar(base: "r")]
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
    }

    func test_singleConsonant_notDetectable() {
        let buffer = [VnChar(base: "f")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_ignoresCharsAfterFirstVowel() {
        // "than" — leading consonants = "th" only, vowel 'a' stops extraction
        let buffer = "than".map { VnChar(base: $0) }
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_emptyBuffer_notDetectable() {
        XCTAssertFalse(detector.isNonVietnamese(buffer: []))
    }
}

// MARK: - B. Engine Integration Tests

final class EnglishDetectionEngineTests: XCTestCase {

    private func engineWithDetector() -> Engine {
        Engine(detector: ConsonantClusterDetector())
    }

    private func type(_ keys: String, into engine: inout Engine) -> EngineOutput {
        var output = EngineOutput(backspaceCount: 0, committedText: "")
        for c in keys {
            output = engine.processKey(key: c, shift: false)
        }
        return output
    }

    // MARK: - B1. English words skip Telex

    func test_frost_skipsTelex() {
        var engine = engineWithDetector()
        let output = type("frost", into: &engine)
        XCTAssertEqual(output.committedText, "frost")
    }

    func test_string_skipsTelex() {
        var engine = engineWithDetector()
        let output = type("string", into: &engine)
        XCTAssertEqual(output.committedText, "string")
    }

    func test_throw_detectedAtThirdConsonant() {
        var engine = engineWithDetector()
        let output = type("throw", into: &engine)
        XCTAssertEqual(output.committedText, "throw")
    }

    func test_chrome_detectedAtThirdConsonant() {
        var engine = engineWithDetector()
        let output = type("chrome", into: &engine)
        XCTAssertEqual(output.committedText, "chrome")
    }

    // MARK: - B2. Vietnamese words still work

    func test_thans_producesThán() {
        var engine = engineWithDetector()
        let output = type("thans", into: &engine)
        XCTAssertEqual(output.committedText, "th\u{00E1}n")
    }

    func test_nghis_producesNghí() {
        var engine = engineWithDetector()
        let output = type("nghis", into: &engine)
        XCTAssertEqual(output.committedText, "ngh\u{00ED}")
    }

    // MARK: - B3. Backward compatibility

    func test_withoutDetector_frost_stillAppliesTelex() {
        var engine = Engine()
        let output = type("frost", into: &engine)
        // Without detector: 's' consumed as tone sắc on 'o' → frót
        XCTAssertEqual(output.committedText, "fr\u{00F3}t")
    }

    // MARK: - B4. Word break resets flag

    func test_wordBreak_resetsNonVietnamese() {
        var engine = engineWithDetector()
        // "fr " → detected, then space resets
        _ = type("fr ", into: &engine)
        // Now "as" → should apply tone (Vietnamese)
        let output = type("as", into: &engine)
        XCTAssertEqual(output.committedText, "\u{00E1}")
    }

    // MARK: - B5. Backspace re-evaluates

    func test_backspace_reevaluatesNonVietnamese() {
        var engine = engineWithDetector()
        _ = type("fr", into: &engine)
        // nonVietnamese = true, now backspace removes 'r'
        _ = engine.processKey(key: "\u{08}", shift: false)
        // buffer = [f], single consonant → nonVietnamese = false
        let output = type("os", into: &engine)
        // 'o' is vowel, 's' is tone sắc → fó
        XCTAssertEqual(output.committedText, "f\u{00F3}")
    }
}
