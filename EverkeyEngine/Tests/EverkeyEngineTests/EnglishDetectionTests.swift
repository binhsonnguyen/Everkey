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

    private func type(_ keys: String, into engine: inout Engine) -> String {
        var screen = ""
        for c in keys {
            let output = engine.processKey(key: c, shift: false)
            screen.removeLast(min(output.backspaceCount, screen.count))
            screen += output.committedText
        }
        return screen
    }

    // MARK: - B1. English words skip Telex

    func test_frost_skipsTelex() {
        var engine = engineWithDetector()
        let screen = type("frost", into: &engine)
        XCTAssertEqual(screen, "frost")
    }

    func test_string_skipsTelex() {
        var engine = engineWithDetector()
        let screen = type("string", into: &engine)
        XCTAssertEqual(screen, "string")
    }

    func test_throw_detectedAtThirdConsonant() {
        var engine = engineWithDetector()
        let screen = type("throw", into: &engine)
        XCTAssertEqual(screen, "throw")
    }

    func test_chrome_detectedAtThirdConsonant() {
        var engine = engineWithDetector()
        let screen = type("chrome", into: &engine)
        XCTAssertEqual(screen, "chrome")
    }

    // MARK: - B2. Vietnamese words still work

    func test_thans_producesThán() {
        var engine = engineWithDetector()
        let screen = type("thans", into: &engine)
        XCTAssertEqual(screen, "th\u{00E1}n")
    }

    func test_nghis_producesNghí() {
        var engine = engineWithDetector()
        let screen = type("nghis", into: &engine)
        XCTAssertEqual(screen, "ngh\u{00ED}")
    }

    // MARK: - B3. Backward compatibility

    func test_withoutDetector_frost_stillAppliesTelex() {
        var engine = Engine()
        let screen = type("frost", into: &engine)
        // Without detector: 's' consumed as tone sắc on 'o' → frót
        XCTAssertEqual(screen, "fr\u{00F3}t")
    }

    // MARK: - B4. Word break resets flag

    func test_wordBreak_resetsNonVietnamese() {
        var engine = engineWithDetector()
        // "fr " → detected, then space resets
        _ = type("fr ", into: &engine)
        // Now "as" → should apply tone (Vietnamese)
        let screen = type("as", into: &engine)
        XCTAssertEqual(screen, "\u{00E1}")
    }

    // MARK: - B5. Backspace re-evaluates

    func test_backspace_reevaluatesNonVietnamese() {
        var engine = engineWithDetector()
        // "fr" → detected, BS removes 'r' → "f" valid → nonVietnamese=false
        // 'o' vowel, 's' tone sắc → "fó"
        let screen = type("fr\u{08}os", into: &engine)
        XCTAssertEqual(screen, "f\u{00F3}")
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
        let screen = type("bold", into: &engine)
        XCTAssertEqual(screen, "bold")
    }

    func test_task_invalidCoda_revertsAppliedTone() {
        // t-a-s-k: 's' applies sắc on 'a' → "ták", then 'k' invalid coda → revert to "task"
        var engine = compositeEngine()
        let screen = type("task", into: &engine)
        XCTAssertEqual(screen, "task")
    }

    func test_self_invalidCoda_thenLiteralF() {
        // s-e-l-f: 'l' invalid coda → detect, 'f' (huyền) becomes literal
        var engine = compositeEngine()
        let screen = type("self", into: &engine)
        XCTAssertEqual(screen, "self")
    }

    func test_bank_invalidCompoundCoda() {
        // b-a-n-k: 'n' valid coda, 'k' makes "nk" invalid → detect
        var engine = compositeEngine()
        let screen = type("bank", into: &engine)
        XCTAssertEqual(screen, "bank")
    }

    func test_bans_validCoda_vietnameseStillWorks() {
        // b-a-n-s: 'n' valid coda, 's' is tone sắc on 'a' → "bán"
        var engine = compositeEngine()
        let screen = type("bans", into: &engine)
        XCTAssertEqual(screen, "b\u{00E1}n")
    }

    func test_bafng_validCoda_vietnameseStillWorks() {
        // b-a-f-n-g: 'f' is huyền on 'a' → "bà", then "ng" valid coda → "bàng"
        var engine = compositeEngine()
        let screen = type("bafng", into: &engine)
        XCTAssertEqual(screen, "b\u{00E0}ng")
    }

    func test_ring_validCoda_notDetected() {
        // r-i-n-g: coda "ng" valid → not detected, output "ring" (no diacritics)
        var engine = compositeEngine()
        let screen = type("ring", into: &engine)
        XCTAssertEqual(screen, "ring")
    }

    func test_backspace_afterCodaDetection_reevaluates() {
        var engine = compositeEngine()
        // "bank" → detected, BS removes 'k' → "ban" valid → nonVietnamese=false
        // 's' applies tone sắc on 'a' → "bán"
        let screen = type("bank\u{08}s", into: &engine)
        XCTAssertEqual(screen, "b\u{00E1}n")
    }

    // MARK: - B7. Invalid vowel nuclei detection (Method 3 integration)

    private func fullCompositeEngine() -> Engine {
        Engine(detector: CompositeDetector([
            ConsonantClusterDetector(),
            InvalidCodaDetector(),
            InvalidVowelNucleiDetector(),
            ToneCodaRestrictionDetector(),
        ]))
    }

    func test_team_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let screen = type("team", into: &engine)
        XCTAssertEqual(screen, "team")
    }

    func test_bean_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let screen = type("bean", into: &engine)
        XCTAssertEqual(screen, "bean")
    }

    func test_heap_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let screen = type("heap", into: &engine)
        XCTAssertEqual(screen, "heap")
    }

    func test_lion_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let screen = type("lion", into: &engine)
        XCTAssertEqual(screen, "lion")
    }

    func test_soup_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let screen = type("soup", into: &engine)
        XCTAssertEqual(screen, "soup")
    }

    func test_noun_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let screen = type("noun", into: &engine)
        XCTAssertEqual(screen, "noun")
    }

    func test_reach_invalidNucleus_skipsTelex() {
        var engine = fullCompositeEngine()
        let screen = type("reach", into: &engine)
        XCTAssertEqual(screen, "reach")
    }

    func test_hoafng_validNucleus_vietnameseWorks() {
        var engine = fullCompositeEngine()
        let screen = type("hoafng", into: &engine)
        XCTAssertEqual(screen, "ho\u{00E0}ng")
    }

    func test_quays_validAfterOnsetSkip_vietnameseWorks() {
        var engine = fullCompositeEngine()
        let screen = type("quays", into: &engine)
        XCTAssertEqual(screen, "qu\u{00E1}y")
    }

    func test_backspace_afterNucleusDetection_reevaluates() {
        var engine = fullCompositeEngine()
        // "tea" → detected, BS → "te" valid → nonVietnamese=false
        // 's' applies tone sắc on 'e' → "té"
        let screen = type("tea\u{08}s", into: &engine)
        XCTAssertEqual(screen, "t\u{00E9}")
    }

    // MARK: - B8. Tone-coda restriction detection (Method 4 integration)

    func test_raft_toneThenCoda_skipsTelex() {
        // r-a-f-t: 'f' huyền on 'a' → "rà", 't' literal → detect (huyền + stop t)
        var engine = fullCompositeEngine()
        let screen = type("raft", into: &engine)
        XCTAssertEqual(screen, "raft")
    }

    func test_daft_toneThenCoda_skipsTelex() {
        var engine = fullCompositeEngine()
        let screen = type("daft", into: &engine)
        XCTAssertEqual(screen, "daft")
    }

    func test_codaThenTone_skipsTelex() {
        // h-a-c-f: 'c' literal, then 'f' huyền on 'a' → detect (huyền + stop c)
        var engine = fullCompositeEngine()
        let screen = type("hacf", into: &engine)
        XCTAssertEqual(screen, "hacf")
    }

    func test_bacs_sacWithStopCoda_vietnameseWorks() {
        // b-a-c-s: 'c' stop coda, 's' sắc on 'a' → "bác" (sắc + c = valid)
        var engine = fullCompositeEngine()
        let screen = type("bacs", into: &engine)
        XCTAssertEqual(screen, "b\u{00E1}c")
    }

    func test_hachj_nangWithStopCoda_vietnameseWorks() {
        // h-a-c-h-j: coda "ch" stop, 'j' nặng on 'a' → "hạch" (nặng + ch = valid)
        var engine = fullCompositeEngine()
        let screen = type("hachj", into: &engine)
        XCTAssertEqual(screen, "h\u{1EA1}ch")
    }

    // MARK: - C. Edge Cases

    func test_Swift_uppercaseSkipsTelex() {
        var engine = engineWithDetector()
        var screen = ""
        for (i, c) in "Swift".enumerated() {
            let output = engine.processKey(key: c, shift: i == 0)
            screen.removeLast(min(output.backspaceCount, screen.count))
            screen += output.committedText
        }
        XCTAssertEqual(screen, "Swift")
    }

    func test_modifier_w_skippedWhenNonVietnamese() {
        // "sw" detected → 'w' would be modifier for 'o'/'u', but should be literal
        var engine = engineWithDetector()
        let screen = type("sword", into: &engine)
        XCTAssertEqual(screen, "sword")
    }

    func test_modifier_dd_skippedWhenNonVietnamese() {
        // "bdd" → 'b' single consonant not detected, but "dd" modifier should still work
        // This is a Vietnamese scenario: "bdd" → the second 'd' toggles stroke on first 'd'
        // Actually "bd" → invalid cluster! b then d → cluster "bd" not valid
        var engine = engineWithDetector()
        let screen = type("bdd", into: &engine)
        // "bd" detected at 2nd char → nonVietnamese, 3rd 'd' literal
        XCTAssertEqual(screen, "bdd")
    }

    // MARK: - D. Runtime Toggle

    func test_setDetector_enables_detection() {
        var engine = Engine() // no detector
        engine.setDetector(ConsonantClusterDetector())
        let screen = type("frost", into: &engine)
        XCTAssertEqual(screen, "frost")
    }

    func test_setDetector_nil_disables_detection() {
        var engine = engineWithDetector()
        _ = type("fr", into: &engine)
        // nonVietnamese = true, now disable detector
        engine.setDetector(nil)
        // nonVietnamese cleared, continue typing → Telex applies
        _ = engine.processKey(key: "o", shift: false)
        let output = engine.processKey(key: "s", shift: false)
        // 's' applies tone sắc on 'o' → confirms Telex is active again
        XCTAssertEqual(output.committedText, "\u{00F3}")
    }
}
