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

// MARK: - A3. CompositeDetector Tests

final class CompositeDetectorTests: XCTestCase {

    private let composite = CompositeDetector([
        ConsonantClusterDetector(),
        InvalidCodaDetector(),
        InvalidVowelNucleiDetector(),
    ])

    func test_prefixCluster_triggersComposite() {
        // "fr" → Method 1 fires
        let buffer = [VnChar(base: "f"), VnChar(base: "r")]
        XCTAssertTrue(composite.isNonVietnamese(buffer: buffer))
    }

    func test_invalidCoda_triggersComposite() {
        // "al" → Method 2 fires (coda "l" invalid)
        let buffer = [VnChar(base: "a"), VnChar(base: "l")]
        XCTAssertTrue(composite.isNonVietnamese(buffer: buffer))
    }

    func test_validVietnamese_neitherTriggers() {
        // "ban" → onset "b" valid, coda "n" valid, nucleus "a" single
        let buffer = "ban".map { VnChar(base: $0) }
        XCTAssertFalse(composite.isNonVietnamese(buffer: buffer))
    }

    func test_invalidNucleus_triggersComposite() {
        // "tea" → nucleus "ea" invalid, Method 3 fires
        let buffer = "tea".map { VnChar(base: $0) }
        XCTAssertTrue(composite.isNonVietnamese(buffer: buffer))
    }
}

// MARK: - A4. InvalidVowelNucleiDetector Tests

final class InvalidVowelNucleiDetectorTests: XCTestCase {

    private let detector = InvalidVowelNucleiDetector()

    // MARK: - Invalid nuclei → detected

    func test_ea_isNonVietnamese() {
        let buffer = "tea".map { VnChar(base: $0) }
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
    }

    func test_ou_isNonVietnamese() {
        let buffer = "sou".map { VnChar(base: $0) }
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
    }

    func test_io_isNonVietnamese() {
        let buffer = "lio".map { VnChar(base: $0) }
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
    }

    func test_ei_isNonVietnamese() {
        let buffer = "hei".map { VnChar(base: $0) }
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
    }

    // MARK: - Valid nuclei → not detected

    func test_singleVowel_notDetected() {
        let buffer = [VnChar(base: "b"), VnChar(base: "a")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_validDiphthongs_areVietnamese() {
        let validPairs = [
            "ai", "ao", "au", "ay", "eo", "eu",
            "ia", "ie", "iu", "oa", "oe", "oi",
            "ua", "ue", "ui", "uo", "uu", "uy", "ye",
        ]
        for pair in validPairs {
            let buffer = [VnChar(base: "b")] + pair.map { VnChar(base: $0) }
            XCTAssertFalse(detector.isNonVietnamese(buffer: buffer),
                           "nucleus '\(pair)' should be valid Vietnamese")
        }
    }

    func test_validTriphthongs_areVietnamese() {
        let validTriples = [
            "ieu", "yeu", "oai", "oay", "oeo",
            "uay", "uoi", "uou", "uya", "uye", "uyu",
        ]
        for triple in validTriples {
            let buffer = [VnChar(base: "b")] + triple.map { VnChar(base: $0) }
            XCTAssertFalse(detector.isNonVietnamese(buffer: buffer),
                           "nucleus '\(triple)' should be valid Vietnamese")
        }
    }

    // MARK: - Onset vowel handling

    func test_quay_skipsOnsetU_nucleusIsAy_valid() {
        let buffer = "quay".map { VnChar(base: $0) }
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_giai_skipsOnsetI_nucleusIsAi_valid() {
        let buffer = "giai".map { VnChar(base: $0) }
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    // MARK: - Edge cases

    func test_emptyBuffer_notDetected() {
        XCTAssertFalse(detector.isNonVietnamese(buffer: []))
    }

    func test_noVowels_notDetected() {
        let buffer = [VnChar(base: "b"), VnChar(base: "r")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_nucleusWithCoda_stillChecksNucleus() {
        let buffer = "team".map { VnChar(base: $0) }
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
    }

    func test_hoang_nucleusIsOa_valid() {
        let buffer = "hoang".map { VnChar(base: $0) }
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }
}

// MARK: - A5. ToneCodaRestrictionDetector Tests

final class ToneCodaRestrictionDetectorTests: XCTestCase {

    private let detector = ToneCodaRestrictionDetector()

    // MARK: - Stop coda + invalid tone → detected

    func test_huyen_with_stopCoda_c_isNonVietnamese() {
        // "hàc" → huyền + stop coda c → invalid
        let buffer = [VnChar(base: "h"), VnChar(base: "a", tone: .huyen), VnChar(base: "c")]
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
    }

    func test_hoi_with_stopCoda_p_isNonVietnamese() {
        // "hảp" → hỏi + stop coda p → invalid
        let buffer = [VnChar(base: "h"), VnChar(base: "a", tone: .hoi), VnChar(base: "p")]
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
    }

    func test_nga_with_stopCoda_t_isNonVietnamese() {
        // "hãt" → ngã + stop coda t → invalid
        let buffer = [VnChar(base: "h"), VnChar(base: "a", tone: .nga), VnChar(base: "t")]
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
    }

    func test_huyen_with_stopCoda_ch_isNonVietnamese() {
        // "hàch" → huyền + stop coda ch → invalid
        let buffer = [VnChar(base: "h"), VnChar(base: "a", tone: .huyen), VnChar(base: "c"), VnChar(base: "h")]
        XCTAssertTrue(detector.isNonVietnamese(buffer: buffer))
    }

    // MARK: - Stop coda + valid tone → not detected

    func test_sac_with_stopCoda_c_isVietnamese() {
        // "bác" → sắc + c → valid
        let buffer = [VnChar(base: "b"), VnChar(base: "a", tone: .sac), VnChar(base: "c")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_nang_with_stopCoda_p_isVietnamese() {
        // "hạp" → nặng + p → valid
        let buffer = [VnChar(base: "h"), VnChar(base: "a", tone: .nang), VnChar(base: "p")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_ngang_with_stopCoda_t_isVietnamese() {
        // "hat" → ngang + t → valid
        let buffer = [VnChar(base: "h"), VnChar(base: "a"), VnChar(base: "t")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    // MARK: - Nasal coda + any tone → not detected

    func test_huyen_with_nasalCoda_n_isVietnamese() {
        // "hàn" → huyền + nasal n → valid
        let buffer = [VnChar(base: "h"), VnChar(base: "a", tone: .huyen), VnChar(base: "n")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_hoi_with_nasalCoda_ng_isVietnamese() {
        // "hảng" → hỏi + nasal ng → valid
        let buffer = [VnChar(base: "h"), VnChar(base: "a", tone: .hoi), VnChar(base: "n"), VnChar(base: "g")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    // MARK: - Edge cases

    func test_emptyBuffer_notDetected() {
        XCTAssertFalse(detector.isNonVietnamese(buffer: []))
    }

    func test_noVowel_notDetected() {
        let buffer = [VnChar(base: "b"), VnChar(base: "r")]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
    }

    func test_noCoda_notDetected() {
        let buffer = [VnChar(base: "h"), VnChar(base: "a", tone: .huyen)]
        XCTAssertFalse(detector.isNonVietnamese(buffer: buffer))
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

    // MARK: - B6. Invalid coda detection (Method 2 integration)

    private func compositeEngine() -> Engine {
        Engine(detector: CompositeDetector([
            ConsonantClusterDetector(),
            InvalidCodaDetector(),
        ]))
    }

    func test_bold_invalidCoda_skipsTelex() {
        var engine = compositeEngine()
        let output = type("bold", into: &engine)
        XCTAssertEqual(output.committedText, "bold")
    }

    func test_task_invalidCoda_revertsAppliedTone() {
        // t-a-s-k: 's' applies sắc on 'a' → "ták", then 'k' invalid coda → revert to "task"
        var engine = compositeEngine()
        let output = type("task", into: &engine)
        XCTAssertEqual(output.committedText, "task")
    }

    func test_self_invalidCoda_thenLiteralF() {
        // s-e-l-f: 'l' invalid coda → detect, 'f' (huyền) becomes literal
        var engine = compositeEngine()
        let output = type("self", into: &engine)
        XCTAssertEqual(output.committedText, "self")
    }

    func test_bank_invalidCompoundCoda() {
        // b-a-n-k: 'n' valid coda, 'k' makes "nk" invalid → detect
        var engine = compositeEngine()
        let output = type("bank", into: &engine)
        XCTAssertEqual(output.committedText, "bank")
    }

    func test_bans_validCoda_vietnameseStillWorks() {
        // b-a-n-s: 'n' valid coda, 's' is tone sắc on 'a' → "bán"
        var engine = compositeEngine()
        let output = type("bans", into: &engine)
        XCTAssertEqual(output.committedText, "b\u{00E1}n")
    }

    func test_bafng_validCoda_vietnameseStillWorks() {
        // b-a-f-n-g: 'f' is huyền on 'a' → "bà", then "ng" valid coda → "bàng"
        var engine = compositeEngine()
        let output = type("bafng", into: &engine)
        XCTAssertEqual(output.committedText, "b\u{00E0}ng")
    }

    func test_ring_validCoda_notDetected() {
        // r-i-n-g: coda "ng" valid → not detected, output "ring" (no diacritics)
        var engine = compositeEngine()
        let output = type("ring", into: &engine)
        XCTAssertEqual(output.committedText, "ring")
    }

    func test_backspace_afterCodaDetection_reevaluates() {
        var engine = compositeEngine()
        // "bank" → detected (coda "nk")
        _ = type("bank", into: &engine)
        // backspace removes 'k' → coda "n" → valid → nonVietnamese = false
        _ = engine.processKey(key: "\u{08}", shift: false)
        // now 's' should apply tone sắc on 'a' → "bán"
        let output = engine.processKey(key: "s", shift: false)
        XCTAssertEqual(output.committedText, "b\u{00E1}n")
    }

    // MARK: - B7. Invalid vowel nuclei detection (Method 3 integration)

    private func fullCompositeEngine() -> Engine {
        Engine(detector: CompositeDetector([
            ConsonantClusterDetector(),
            InvalidCodaDetector(),
            InvalidVowelNucleiDetector(),
        ]))
    }

    func test_team_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let output = type("team", into: &engine)
        XCTAssertEqual(output.committedText, "team")
    }

    func test_bean_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let output = type("bean", into: &engine)
        XCTAssertEqual(output.committedText, "bean")
    }

    func test_heap_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let output = type("heap", into: &engine)
        XCTAssertEqual(output.committedText, "heap")
    }

    func test_lion_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let output = type("lion", into: &engine)
        XCTAssertEqual(output.committedText, "lion")
    }

    func test_soup_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let output = type("soup", into: &engine)
        XCTAssertEqual(output.committedText, "soup")
    }

    func test_noun_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let output = type("noun", into: &engine)
        XCTAssertEqual(output.committedText, "noun")
    }

    func test_reach_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let output = type("reach", into: &engine)
        XCTAssertEqual(output.committedText, "reach")
    }

    func test_hoafng_validNucleus_vietnameseWorks() {
        var engine = fullCompositeEngine()
        let output = type("hoafng", into: &engine)
        XCTAssertEqual(output.committedText, "ho\u{00E0}ng")
    }

    func test_quays_validAfterOnsetSkip_vietnameseWorks() {
        var engine = fullCompositeEngine()
        let output = type("quays", into: &engine)
        XCTAssertEqual(output.committedText, "qu\u{00E1}y")
    }

    func test_backspace_afterNucleusDetection_reevaluates() {
        var engine = fullCompositeEngine()
        // "tea" → nucleus "ea" → detected
        _ = type("tea", into: &engine)
        // backspace removes 'a' → nucleus "e" (single) → valid → nonVietnamese = false
        _ = engine.processKey(key: "\u{08}", shift: false)
        // now 's' should apply tone sắc on 'e' → "té"
        let output = engine.processKey(key: "s", shift: false)
        XCTAssertEqual(output.committedText, "t\u{00E9}")
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
