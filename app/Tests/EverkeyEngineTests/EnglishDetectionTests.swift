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

// MARK: - A2. InvalidCodaDetector Tests

final class InvalidCodaDetectorTests: XCTestCase {

    private let detector = InvalidCodaDetector()

    // MARK: - Valid codas → not detected

    func test_validCodas_areVietnamese() {
        let validCodas = ["c", "ch", "m", "n", "ng", "nh", "p", "t"]
        for coda in validCodas {
            let buffer = [VnChar(base: "a")] + coda.map { VnChar(base: $0) }
            XCTAssertFalse(detector.isNonVietnamese(buffer: buffer),
                           "coda '\(coda)' should be valid Vietnamese")
        }
    }

    func test_noCoda_notDetected() {
        let buffer = [VnChar(base: "b"), VnChar(base: "a")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    // MARK: - Invalid single codas → detected

    func test_invalidSingleCodas_detected() {
        let invalidCodas: [Character] = ["b", "d", "g", "h", "k", "l", "r", "s", "v", "x"]
        for coda in invalidCodas {
            let buffer = [VnChar(base: "a"), VnChar(base: coda)]
            XCTAssertTrue(detector.isNonVietnamese(buffer: buffer),
                          "coda '\(coda)' should be invalid Vietnamese")
        }
    }

    // MARK: - Invalid compound codas → detected

    func test_invalidCompoundCodas_detected() {
        let invalidCodas = ["ld", "rk", "nk", "nd", "lp", "lf", "st", "rb"]
        for coda in invalidCodas {
            let buffer = [VnChar(base: "a")] + coda.map { VnChar(base: $0) }
            XCTAssertTrue(detector.isNonVietnamese(buffer: buffer),
                          "coda '\(coda)' should be invalid Vietnamese")
        }
    }

    // MARK: - Edge cases

    func test_noVowel_notDetected() {
        let buffer = [VnChar(base: "b"), VnChar(base: "r")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_emptyBuffer_notDetected() {
        XCTAssertFalse(detector.isNonVietnamese(buffer: []))
    }

    func test_onlyVowel_notDetected() {
        let buffer = [VnChar(base: "a")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_onset_plus_validCoda() {
        // "ban" → onset b, vowel a, coda n → valid
        let buffer = "ban".map { VnChar(base: $0) }
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_onset_plus_invalidCoda() {
        // "bal" → onset b, vowel a, coda l → invalid
        let buffer = "bal".map { VnChar(base: $0) }
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
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

    // MARK: - C. Edge Cases

    func test_Swift_uppercaseSkipsTelex() {
        var engine = engineWithDetector()
        let _ = engine.processKey(key: "s", shift: true) // S
        let _ = engine.processKey(key: "w", shift: false)
        let _ = engine.processKey(key: "i", shift: false)
        let _ = engine.processKey(key: "f", shift: false)
        let output = engine.processKey(key: "t", shift: false)
        XCTAssertEqual(output.committedText, "Swift")
    }

    func test_modifier_w_skippedWhenNonVietnamese() {
        // "sw" detected → 'w' would be modifier for 'o'/'u', but should be literal
        var engine = engineWithDetector()
        let output = type("sword", into: &engine)
        XCTAssertEqual(output.committedText, "sword")
    }

    func test_modifier_dd_skippedWhenNonVietnamese() {
        // "bdd" → 'b' single consonant not detected, but "dd" modifier should still work
        // This is a Vietnamese scenario: "bdd" → the second 'd' toggles stroke on first 'd'
        // Actually "bd" → invalid cluster! b then d → cluster "bd" not valid
        var engine = engineWithDetector()
        let output = type("bdd", into: &engine)
        // "bd" detected at 2nd char → nonVietnamese, 3rd 'd' literal
        XCTAssertEqual(output.committedText, "bdd")
    }

    // MARK: - D. Runtime Toggle

    func test_setDetector_enables_detection() {
        var engine = Engine() // no detector
        engine.setDetector(ConsonantClusterDetector())
        let output = type("frost", into: &engine)
        XCTAssertEqual(output.committedText, "frost")
    }

    func test_setDetector_nil_disables_detection() {
        var engine = engineWithDetector()
        _ = type("fr", into: &engine)
        // nonVietnamese = true, now disable detector
        engine.setDetector(nil)
        // nonVietnamese cleared, continue typing → Telex applies
        _ = engine.processKey(key: "o", shift: false)
        let output = engine.processKey(key: "s", shift: false)
        // 'o' is vowel, 's' tone sắc → fró
        XCTAssertEqual(output.committedText, "fr\u{00F3}")
    }
}
