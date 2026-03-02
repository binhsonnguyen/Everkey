import XCTest
@testable import EverkeyEngine

final class AdvancedEngineTests: XCTestCase {

    // =========================================================================
    // MARK: - A. Unicode Map Coverage (72 characters)
    // Thuật toán: 12 base vowels × 6 tones = 72 ký tự
    // =========================================================================

    func test_A_unicodeMap_a_family() {
        // a (no modifier): a, á, à, ả, ã, ạ
        assertTelex([
            TelexTestCase("a",  "a",        "a ngang"),
            TelexTestCase("as", "\u{00E1}",  "a sắc = á"),
            TelexTestCase("af", "\u{00E0}",  "a huyền = à"),
            TelexTestCase("ar", "\u{1EA3}",  "a hỏi = ả"),
            TelexTestCase("ax", "\u{00E3}",  "a ngã = ã"),
            TelexTestCase("aj", "\u{1EA1}",  "a nặng = ạ"),
        ])
    }

    func test_A_unicodeMap_a_circumflex_family() {
        // â: â, ấ, ầ, ẩ, ẫ, ậ
        assertTelex([
            TelexTestCase("aa",  "\u{00E2}",  "â ngang"),
            TelexTestCase("aas", "\u{1EA5}",  "â sắc = ấ"),
            TelexTestCase("aaf", "\u{1EA7}",  "â huyền = ầ"),
            TelexTestCase("aar", "\u{1EA9}",  "â hỏi = ẩ"),
            TelexTestCase("aax", "\u{1EAB}",  "â ngã = ẫ"),
            TelexTestCase("aaj", "\u{1EAD}",  "â nặng = ậ"),
        ])
    }

    func test_A_unicodeMap_a_breve_family() {
        // ă: ă, ắ, ằ, ẳ, ẵ, ặ
        assertTelex([
            TelexTestCase("aw",  "\u{0103}",  "ă ngang"),
            TelexTestCase("aws", "\u{1EAF}",  "ă sắc = ắ"),
            TelexTestCase("awf", "\u{1EB1}",  "ă huyền = ằ"),
            TelexTestCase("awr", "\u{1EB3}",  "ă hỏi = ẳ"),
            TelexTestCase("awx", "\u{1EB5}",  "ă ngã = ẵ"),
            TelexTestCase("awj", "\u{1EB7}",  "ă nặng = ặ"),
        ])
    }

    func test_A_unicodeMap_e_family() {
        // e: e, é, è, ẻ, ẽ, ẹ
        assertTelex([
            TelexTestCase("e",  "e",        "e ngang"),
            TelexTestCase("es", "\u{00E9}",  "e sắc = é"),
            TelexTestCase("ef", "\u{00E8}",  "e huyền = è"),
            TelexTestCase("er", "\u{1EBB}",  "e hỏi = ẻ"),
            TelexTestCase("ex", "\u{1EBD}",  "e ngã = ẽ"),
            TelexTestCase("ej", "\u{1EB9}",  "e nặng = ẹ"),
        ])
    }

    func test_A_unicodeMap_e_circumflex_family() {
        // ê: ê, ế, ề, ể, ễ, ệ
        assertTelex([
            TelexTestCase("ee",  "\u{00EA}",  "ê ngang"),
            TelexTestCase("ees", "\u{1EBF}",  "ê sắc = ế"),
            TelexTestCase("eef", "\u{1EC1}",  "ê huyền = ề"),
            TelexTestCase("eer", "\u{1EC3}",  "ê hỏi = ể"),
            TelexTestCase("eex", "\u{1EC5}",  "ê ngã = ễ"),
            TelexTestCase("eej", "\u{1EC7}",  "ê nặng = ệ"),
        ])
    }

    func test_A_unicodeMap_i_family() {
        // i: i, í, ì, ỉ, ĩ, ị
        assertTelex([
            TelexTestCase("i",  "i",        "i ngang"),
            TelexTestCase("is", "\u{00ED}",  "i sắc = í"),
            TelexTestCase("if", "\u{00EC}",  "i huyền = ì"),
            TelexTestCase("ir", "\u{1EC9}",  "i hỏi = ỉ"),
            TelexTestCase("ix", "\u{0129}",  "i ngã = ĩ"),
            TelexTestCase("ij", "\u{1ECB}",  "i nặng = ị"),
        ])
    }

    func test_A_unicodeMap_o_family() {
        // o: o, ó, ò, ỏ, õ, ọ
        assertTelex([
            TelexTestCase("o",  "o",        "o ngang"),
            TelexTestCase("os", "\u{00F3}",  "o sắc = ó"),
            TelexTestCase("of", "\u{00F2}",  "o huyền = ò"),
            TelexTestCase("or", "\u{1ECF}",  "o hỏi = ỏ"),
            TelexTestCase("ox", "\u{00F5}",  "o ngã = õ"),
            TelexTestCase("oj", "\u{1ECD}",  "o nặng = ọ"),
        ])
    }

    func test_A_unicodeMap_o_circumflex_family() {
        // ô: ô, ố, ồ, ổ, ỗ, ộ
        assertTelex([
            TelexTestCase("oo",  "\u{00F4}",  "ô ngang"),
            TelexTestCase("oos", "\u{1ED1}",  "ô sắc = ố"),
            TelexTestCase("oof", "\u{1ED3}",  "ô huyền = ồ"),
            TelexTestCase("oor", "\u{1ED5}",  "ô hỏi = ổ"),
            TelexTestCase("oox", "\u{1ED7}",  "ô ngã = ỗ"),
            TelexTestCase("ooj", "\u{1ED9}",  "ô nặng = ộ"),
        ])
    }

    func test_A_unicodeMap_o_horn_family() {
        // ơ: ơ, ớ, ờ, ở, ỡ, ợ
        assertTelex([
            TelexTestCase("ow",  "\u{01A1}",  "ơ ngang"),
            TelexTestCase("ows", "\u{1EDB}",  "ơ sắc = ớ"),
            TelexTestCase("owf", "\u{1EDD}",  "ơ huyền = ờ"),
            TelexTestCase("owr", "\u{1EDF}",  "ơ hỏi = ở"),
            TelexTestCase("owx", "\u{1EE1}",  "ơ ngã = ỡ"),
            TelexTestCase("owj", "\u{1EE3}",  "ơ nặng = ợ"),
        ])
    }

    func test_A_unicodeMap_u_family() {
        // u: u, ú, ù, ủ, ũ, ụ
        assertTelex([
            TelexTestCase("u",  "u",        "u ngang"),
            TelexTestCase("us", "\u{00FA}",  "u sắc = ú"),
            TelexTestCase("uf", "\u{00F9}",  "u huyền = ù"),
            TelexTestCase("ur", "\u{1EE7}",  "u hỏi = ủ"),
            TelexTestCase("ux", "\u{0169}",  "u ngã = ũ"),
            TelexTestCase("uj", "\u{1EE5}",  "u nặng = ụ"),
        ])
    }

    func test_A_unicodeMap_u_horn_family() {
        // ư: ư, ứ, ừ, ử, ữ, ự
        assertTelex([
            TelexTestCase("uw",  "\u{01B0}",  "ư ngang"),
            TelexTestCase("uws", "\u{1EE9}",  "ư sắc = ứ"),
            TelexTestCase("uwf", "\u{1EEB}",  "ư huyền = ừ"),
            TelexTestCase("uwr", "\u{1EED}",  "ư hỏi = ử"),
            TelexTestCase("uwx", "\u{1EEF}",  "ư ngã = ữ"),
            TelexTestCase("uwj", "\u{1EF1}",  "ư nặng = ự"),
        ])
    }

    func test_A_unicodeMap_y_family() {
        // y: y, ý, ỳ, ỷ, ỹ, ỵ
        assertTelex([
            TelexTestCase("y",  "y",        "y ngang"),
            TelexTestCase("ys", "\u{00FD}",  "y sắc = ý"),
            TelexTestCase("yf", "\u{1EF3}",  "y huyền = ỳ"),
            TelexTestCase("yr", "\u{1EF7}",  "y hỏi = ỷ"),
            TelexTestCase("yx", "\u{1EF9}",  "y ngã = ỹ"),
            TelexTestCase("yj", "\u{1EF5}",  "y nặng = ỵ"),
        ])
    }

    // =========================================================================
    // MARK: - B. Typing Behavior Patterns
    // =========================================================================

    // MARK: B1. Flexible order — "thường" (th + ươ + ng, horn=w, tone=f, coda=ng)

    func test_B1_flexible_thuong_modifier_tone_coda() {
        XCTAssertEqual(typeSequence("thuowfng"), "th\u{01B0}\u{1EDD}ng") // thường
    }

    func test_B1_flexible_thuong_modifier_coda_tone() {
        XCTAssertEqual(typeSequence("thuowngf"), "th\u{01B0}\u{1EDD}ng")
    }

    func test_B1_flexible_thuong_tone_modifier_coda() {
        XCTAssertEqual(typeSequence("thuofwng"), "th\u{01B0}\u{1EDD}ng")
    }

    func test_B1_flexible_thuong_tone_coda_modifier() {
        XCTAssertEqual(typeSequence("thuofngw"), "th\u{01B0}\u{1EDD}ng")
    }

    func test_B1_flexible_thuong_coda_modifier_tone() {
        XCTAssertEqual(typeSequence("thuongwf"), "th\u{01B0}\u{1EDD}ng")
    }

    func test_B1_flexible_thuong_coda_tone_modifier() {
        XCTAssertEqual(typeSequence("thuongfw"), "th\u{01B0}\u{1EDD}ng")
    }

    // MARK: B1. Flexible order — "nước" (n + ươ + c, horn=w, tone=s, coda=c)

    func test_B1_flexible_nuoc_modifier_tone_coda() {
        XCTAssertEqual(typeSequence("nuowsc"), "n\u{01B0}\u{1EDB}c") // nước
    }

    func test_B1_flexible_nuoc_modifier_coda_tone() {
        XCTAssertEqual(typeSequence("nuowcs"), "n\u{01B0}\u{1EDB}c")
    }

    func test_B1_flexible_nuoc_tone_modifier_coda() {
        XCTAssertEqual(typeSequence("nuoswc"), "n\u{01B0}\u{1EDB}c")
    }

    func test_B1_flexible_nuoc_tone_coda_modifier() {
        XCTAssertEqual(typeSequence("nuoscw"), "n\u{01B0}\u{1EDB}c")
    }

    func test_B1_flexible_nuoc_coda_modifier_tone() {
        XCTAssertEqual(typeSequence("nuocws"), "n\u{01B0}\u{1EDB}c")
    }

    func test_B1_flexible_nuoc_coda_tone_modifier() {
        XCTAssertEqual(typeSequence("nuocsw"), "n\u{01B0}\u{1EDB}c")
    }

    // MARK: B2. Toggle modifier — tất cả 7 modifier

    func test_B2_toggle_modifier_all() {
        assertTelex([
            TelexTestCase("aaa", "aa",  "circumflex a toggle"),
            TelexTestCase("eee", "ee",  "circumflex e toggle"),
            TelexTestCase("ooo", "oo",  "circumflex o toggle"),
            TelexTestCase("aww", "aw",  "breve a toggle"),
            TelexTestCase("oww", "ow",  "horn o toggle"),
            TelexTestCase("uww", "uw",  "horn u toggle"),
            TelexTestCase("ddd", "dd",  "stroke d toggle"),
        ])
    }

    // MARK: B3. Toggle tone — tất cả 5 tone

    func test_B3_toggle_tone_all() {
        assertTelex([
            TelexTestCase("ass", "as",  "sắc toggle"),
            TelexTestCase("aff", "af",  "huyền toggle"),
            TelexTestCase("arr", "ar",  "hỏi toggle"),
            TelexTestCase("axx", "ax",  "ngã toggle"),
            TelexTestCase("ajj", "aj",  "nặng toggle"),
        ])
    }

    // MARK: B4. Tone replacement — 5×4 = 20 cặp

    func test_B4_tone_replacement_from_sac() {
        assertTelex([
            TelexTestCase("asf", "\u{00E0}",  "sắc → huyền"),
            TelexTestCase("asr", "\u{1EA3}",  "sắc → hỏi"),
            TelexTestCase("asx", "\u{00E3}",  "sắc → ngã"),
            TelexTestCase("asj", "\u{1EA1}",  "sắc → nặng"),
        ])
    }

    func test_B4_tone_replacement_from_huyen() {
        assertTelex([
            TelexTestCase("afs", "\u{00E1}",  "huyền → sắc"),
            TelexTestCase("afr", "\u{1EA3}",  "huyền → hỏi"),
            TelexTestCase("afx", "\u{00E3}",  "huyền → ngã"),
            TelexTestCase("afj", "\u{1EA1}",  "huyền → nặng"),
        ])
    }

    func test_B4_tone_replacement_from_hoi() {
        assertTelex([
            TelexTestCase("ars", "\u{00E1}",  "hỏi → sắc"),
            TelexTestCase("arf", "\u{00E0}",  "hỏi → huyền"),
            TelexTestCase("arx", "\u{00E3}",  "hỏi → ngã"),
            TelexTestCase("arj", "\u{1EA1}",  "hỏi → nặng"),
        ])
    }

    func test_B4_tone_replacement_from_nga() {
        assertTelex([
            TelexTestCase("axs", "\u{00E1}",  "ngã → sắc"),
            TelexTestCase("axf", "\u{00E0}",  "ngã → huyền"),
            TelexTestCase("axr", "\u{1EA3}",  "ngã → hỏi"),
            TelexTestCase("axj", "\u{1EA1}",  "ngã → nặng"),
        ])
    }

    func test_B4_tone_replacement_from_nang() {
        assertTelex([
            TelexTestCase("ajs", "\u{00E1}",  "nặng → sắc"),
            TelexTestCase("ajf", "\u{00E0}",  "nặng → huyền"),
            TelexTestCase("ajr", "\u{1EA3}",  "nặng → hỏi"),
            TelexTestCase("ajx", "\u{00E3}",  "nặng → ngã"),
        ])
    }

    // MARK: B5. Remove tone (z)

    func test_B5_remove_tone_basic() {
        assertTelex([
            TelexTestCase("asz",   "a",        "remove sắc from a"),
            TelexTestCase("afz",   "a",        "remove huyền from a"),
            TelexTestCase("aasz",  "\u{00E2}", "remove sắc from â → â ngang"),
            TelexTestCase("awsz",  "\u{0103}", "remove sắc from ắ → ă ngang"),
        ])
    }

    // MARK: B6. Backspace correction

    func test_B6_backspace_removes_last_char() {
        var engine = Engine()
        typeInto(&engine, keys: "vi")
        _ = engine.processKey(key: "\u{08}", shift: false)
        let output = engine.processKey(key: "a", shift: false)
        // Incremental output: prev="v", new="va", common prefix="v", delta="a"
        XCTAssertEqual(output.committedText, "a")
    }

    func test_B6_backspace_after_modifier() {
        // Type "aa" (â), then backspace removes the â char, leaving empty
        var engine = Engine()
        typeInto(&engine, keys: "aa") // â
        let output = engine.processKey(key: "\u{08}", shift: false)
        XCTAssertEqual(output.committedText, "")
    }

    func test_B6_backspace_multiple_then_retype() {
        var engine = Engine()
        typeInto(&engine, keys: "vie")
        _ = engine.processKey(key: "\u{08}", shift: false) // remove e
        _ = engine.processKey(key: "\u{08}", shift: false) // remove i
        let output = engine.processKey(key: "a", shift: false)
        // Incremental output: prev="v", new="va", common prefix="v", delta="a"
        XCTAssertEqual(output.committedText, "a")
    }

    func test_B6_backspace_on_empty_buffer() {
        var engine = Engine()
        let output = engine.processKey(key: "\u{08}", shift: false)
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: ""))
    }

    func test_B6_backspace_past_buffer_start() {
        var engine = Engine()
        typeInto(&engine, keys: "a")
        _ = engine.processKey(key: "\u{08}", shift: false) // remove a
        let output = engine.processKey(key: "\u{08}", shift: false) // empty, no crash
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: ""))
    }

    // MARK: B7. Revert

    func test_B7_revert_simple_tone() {
        var engine = Engine()
        typeInto(&engine, keys: "as")
        let output = engine.revert()
        XCTAssertEqual(output, EngineOutput(backspaceCount: 1, committedText: "as"))
    }

    func test_B7_revert_complex_word() {
        var engine = Engine()
        typeInto(&engine, keys: "thuowfng")
        let output = engine.revert()
        // "thường" = 6 displayed chars, raw = "thuowfng"
        XCTAssertEqual(output.committedText, "thuowfng")
    }

    func test_B7_revert_uppercase() {
        var engine = Engine()
        typeInto(&engine, keys: "A", shiftFirst: true)
        typeInto(&engine, keys: "s")
        let output = engine.revert()
        XCTAssertEqual(output.committedText, "As")
    }

    func test_B7_revert_then_continue_typing() {
        var engine = Engine()
        typeInto(&engine, keys: "as") // á
        _ = engine.revert() // → "as", buffer reset
        let result = screenText(&engine, keys: "bf")
        // After revert, buffer is clean. "bf" → b is literal, f has no vowel → literal
        XCTAssertEqual(result, "bf")
    }

    func test_B7_revert_modifier_word() {
        var engine = Engine()
        typeInto(&engine, keys: "ddeef") // đề
        let output = engine.revert()
        XCTAssertEqual(output.committedText, "ddeef")
    }

    // =========================================================================
    // MARK: - C. Context Switching
    // =========================================================================

    // MARK: C1. Word break characters — đại diện

    func test_C1_wordBreak_space() {
        var engine = Engine()
        typeInto(&engine, keys: "as") // á
        _ = engine.processKey(key: " ", shift: false) // word break
        let output = engine.processKey(key: "b", shift: false)
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "b"))
    }

    func test_C1_wordBreak_tab() {
        var engine = Engine()
        typeInto(&engine, keys: "as")
        _ = engine.processKey(key: "\t", shift: false)
        let output = engine.processKey(key: "b", shift: false)
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "b"))
    }

    func test_C1_wordBreak_newline() {
        var engine = Engine()
        typeInto(&engine, keys: "as")
        _ = engine.processKey(key: "\n", shift: false)
        let output = engine.processKey(key: "b", shift: false)
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "b"))
    }

    func test_C1_wordBreak_digits() {
        let digits: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        for d in digits {
            var engine = Engine()
            typeInto(&engine, keys: "as")
            _ = engine.processKey(key: d, shift: false)
            let output = engine.processKey(key: "b", shift: false)
            XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "b"),
                           "digit '\(d)' should be word break")
        }
    }

    func test_C1_wordBreak_punctuation() {
        let puncts: [Character] = [".", ",", ";", ":", "!", "?", "(", ")", "-", "/"]
        for p in puncts {
            var engine = Engine()
            typeInto(&engine, keys: "as")
            _ = engine.processKey(key: p, shift: false)
            let output = engine.processKey(key: "b", shift: false)
            XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "b"),
                           "punct '\(p)' should be word break")
        }
    }

    // MARK: C2. Context transitions

    func test_C2_vietnamese_then_english() {
        var engine = Engine()
        typeInto(&engine, keys: "chaof") // chào
        _ = engine.processKey(key: " ", shift: false)
        let result = screenText(&engine, keys: "hello")
        XCTAssertEqual(result, "hello")
    }

    func test_C2_english_then_vietnamese() {
        var engine = Engine()
        typeInto(&engine, keys: "hello")
        _ = engine.processKey(key: " ", shift: false)
        let result = screenText(&engine, keys: "chaof")
        XCTAssertEqual(result, "ch\u{00E0}o") // chào
    }

    func test_C2_vietnamese_number_vietnamese() {
        var engine = Engine()
        typeInto(&engine, keys: "as") // á
        _ = engine.processKey(key: "1", shift: false)
        _ = engine.processKey(key: "2", shift: false)
        let output = typeInto(&engine, keys: "ef")
        XCTAssertEqual(output.committedText, "\u{00E8}") // è (fresh buffer after numbers)
    }

    func test_C2_vietnamese_punct_vietnamese() {
        var engine = Engine()
        typeInto(&engine, keys: "chaof") // chào
        _ = engine.processKey(key: ",", shift: false)
        _ = engine.processKey(key: " ", shift: false)
        let result = screenText(&engine, keys: "banj")
        XCTAssertEqual(result, "b\u{1EA1}n") // bạn
    }

    func test_C2_no_state_leak_after_modifier() {
        // After circumflex + word break, no modifier state leaks
        var engine = Engine()
        typeInto(&engine, keys: "aas") // ấ
        _ = engine.processKey(key: " ", shift: false)
        let output = engine.processKey(key: "e", shift: false)
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "e"))
    }

    func test_C2_no_state_leak_after_stroke() {
        var engine = Engine()
        typeInto(&engine, keys: "dd") // đ
        _ = engine.processKey(key: " ", shift: false)
        let output = engine.processKey(key: "d", shift: false)
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "d"))
    }

    // MARK: C3. Active/inactive toggle

    func test_C3_inactive_passes_through_all_keys() {
        var engine = Engine()
        engine.setActive(false)
        let output1 = engine.processKey(key: "a", shift: false)
        let output2 = engine.processKey(key: "s", shift: false)
        XCTAssertEqual(output1.committedText, "a")
        XCTAssertEqual(output2.committedText, "s")
    }

    func test_C3_deactivate_clears_buffer_midword() {
        var engine = Engine()
        typeInto(&engine, keys: "vi") // buffer has [v, i]
        engine.setActive(false) // buffer cleared
        let output = engine.processKey(key: "e", shift: false)
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "e"))
    }

    func test_C3_reactivate_resumes_vietnamese() {
        var engine = Engine()
        engine.setActive(false)
        _ = engine.processKey(key: "a", shift: false) // pass-through
        engine.setActive(true)
        _ = engine.processKey(key: "a", shift: false) // literal a
        let output = engine.processKey(key: "s", shift: false) // sắc
        XCTAssertEqual(output.committedText, "\u{00E1}") // á
    }

    func test_C3_rapid_toggle() {
        var engine = Engine()

        // Active: type "as" → á
        typeInto(&engine, keys: "as")

        // Deactivate mid-word
        engine.setActive(false)
        let pass1 = engine.processKey(key: "a", shift: false)
        let pass2 = engine.processKey(key: "s", shift: false)
        XCTAssertEqual(pass1.committedText, "a")
        XCTAssertEqual(pass2.committedText, "s")

        // Reactivate
        engine.setActive(true)
        _ = engine.processKey(key: "a", shift: false)
        let output = engine.processKey(key: "f", shift: false)
        XCTAssertEqual(output.committedText, "\u{00E0}") // à
    }

    // MARK: C4. Revert mid-sentence then continue

    func test_C4_revert_then_type_vietnamese() {
        var engine = Engine()
        typeInto(&engine, keys: "tois") // tói or similar
        _ = engine.revert() // back to "tois", buffer reset
        let result = screenText(&engine, keys: "laf")
        XCTAssertEqual(result, "l\u{00E0}") // là
    }

    func test_C4_revert_then_word_break_then_type() {
        var engine = Engine()
        typeInto(&engine, keys: "as")
        _ = engine.revert() // → "as"
        // After revert, buffer is empty, but we haven't typed a space
        // Type a space then a new word
        _ = engine.processKey(key: " ", shift: false)
        let output = typeInto(&engine, keys: "ef")
        XCTAssertEqual(output.committedText, "\u{00E8}") // è
    }

    func test_C4_double_revert() {
        var engine = Engine()
        typeInto(&engine, keys: "as") // á
        _ = engine.revert() // → "as"
        // Now buffer is empty. Revert again should be no-op
        let output = engine.revert()
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: ""))
    }

    // =========================================================================
    // MARK: - D. Paragraph Simulation
    // =========================================================================

    // MARK: D1. Pure Vietnamese — "Xin chào bạn đến với Việt Nam"

    func test_D1_pure_vietnamese_sentence() {
        // Each tuple: (telex_keys, expected_output, uppercase_first)
        let words: [(String, String, Bool)] = [
            ("Xin",    "Xin",                          true),
            ("chaof",  "ch\u{00E0}o",                  false), // chào
            ("banj",   "b\u{1EA1}n",                   false), // bạn
            ("ddeens", "\u{0111}\u{1EBF}n",            false), // đến
            ("vowis",  "v\u{1EDB}i",                   false), // với
            ("Vieejt", "Vi\u{1EC7}t",                  true),  // Việt
            ("Nam",    "Nam",                           true),
        ]
        for (keys, expected, uc) in words {
            XCTAssertEqual(typeSequence(keys, uppercaseFirst: uc), expected,
                           "Word: \(keys)")
        }
    }

    // MARK: D1b. Pure Vietnamese — đủ loại dấu + thanh

    func test_D1b_diverse_diacritics() {
        // Cover: â, ă, ê, ô, ơ, ư, đ + all 6 tones
        let words: [(String, String, Bool)] = [
            ("aas",    "\u{1EA5}",              false), // ấ (â + sắc)
            ("awf",    "\u{1EB1}",              false), // ằ (ă + huyền)
            ("eer",    "\u{1EC3}",              false), // ể (ê + hỏi)
            ("oox",    "\u{1ED7}",              false), // ỗ (ô + ngã)
            ("owj",    "\u{1EE3}",              false), // ợ (ơ + nặng)
            ("uws",    "\u{1EE9}",              false), // ứ (ư + sắc)
            ("dd",     "\u{0111}",              false), // đ
        ]
        for (keys, expected, uc) in words {
            XCTAssertEqual(typeSequence(keys, uppercaseFirst: uc), expected,
                           "Word: \(keys)")
        }
    }

    // MARK: D2. Vietnamese + English mixed

    func test_D2_mixed_vietnamese_english() {
        let words: [(String, String, Bool)] = [
            ("Tooi",   "T\u{00F4}i",           true),  // Tôi
            ("hocj",   "h\u{1ECD}c",           false), // học
            ("Swift",  "Sw\u{00EC}t",           true),  // "Swift" in VN mode: 'if' → ì
            ("vaf",    "v\u{00E0}",            false), // và
            ("Python", "Python",                true),  // English
        ]
        for (keys, expected, uc) in words {
            XCTAssertEqual(typeSequence(keys, uppercaseFirst: uc), expected,
                           "Word: \(keys)")
        }
    }

    // MARK: D2b. English words that contain Telex trigger keys

    func test_D2b_english_words_with_telex_triggers() {
        // Words like "see", "off", "add" contain trigger keys (ee, ff, dd)
        // In Vietnamese mode, these get modified — user would need revert
        let words: [(String, String)] = [
            ("see",    "s\u{00EA}"),       // s + ê (ee triggers circumflex!)
            ("off",    "of"),              // o+f→ò, f again→toggle undo→"of"
            ("add",    "a\u{0111}"),       // a + đ (dd triggers stroke)
            ("all",    "all"),             // no triggers
            ("hello",  "hello"),           // no triggers
            ("boss",   "bos"),             // b+o+s→bó, s again→toggle undo→"bos"
        ]
        for (keys, expected) in words {
            XCTAssertEqual(typeSequence(keys), expected,
                           "English word '\(keys)' in VN mode")
        }
    }

    // MARK: D3. Numbers + special characters

    func test_D3_numbers_in_sentence() {
        // "Năm 2024 có" → type each word separately through engine
        var engine = Engine()

        // "Nawm" → Năm
        _ = typeInto(&engine, keys: "N", shiftFirst: true)
        typeInto(&engine, keys: "awm")
        // word break
        _ = engine.processKey(key: " ", shift: false)

        // "2024" — each digit is a word break
        for c in "2024" {
            _ = engine.processKey(key: c, shift: false)
        }

        // space
        _ = engine.processKey(key: " ", shift: false)

        // "cos" → có
        let result = screenText(&engine, keys: "cos")
        XCTAssertEqual(result, "c\u{00F3}") // có
    }

    func test_D3_email_address() {
        // test@gmail.com — @, ., are all word breaks
        var engine = Engine()

        // "test" → literal (no Telex triggers)
        typeInto(&engine, keys: "test")

        // @ is word break
        _ = engine.processKey(key: "@", shift: false)

        // "gmail" → literal
        typeInto(&engine, keys: "gmail")

        // . is word break
        _ = engine.processKey(key: ".", shift: false)

        // "com"
        let result = screenText(&engine, keys: "com")
        XCTAssertEqual(result, "com")
    }

    func test_D3_phone_number_between_words() {
        // "gọi 0901234567 nhé"
        var engine = Engine()

        typeInto(&engine, keys: "goij") // gọi
        _ = engine.processKey(key: " ", shift: false)

        // Phone number — each digit is word break
        for c in "0901234567" {
            _ = engine.processKey(key: c, shift: false)
        }
        _ = engine.processKey(key: " ", shift: false)

        // "nhes" → nhé
        let result = screenText(&engine, keys: "nhes")
        XCTAssertEqual(result, "nh\u{00E9}") // nhé
    }

    // MARK: D4. Typo correction

    func test_D4_backspace_removes_char_not_tone() {
        // 'r' applied hỏi tone to 'i'. Backspace removes the CHAR (i), not the tone.
        // After BS: buffer = [v]. Then "eejt" → "vệt" (not "việt").
        // This shows: to undo a tone, use toggle (type same key again), not backspace.
        var engine = Engine()
        // Use screenText for the full sequence to verify the accumulated result
        let result = screenText(&engine, keys: "vir\u{08}eejt")
        XCTAssertEqual(result, "v\u{1EC7}t") // vệt (not việt!)
    }

    func test_D4_toggle_to_undo_wrong_tone() {
        // Correct way to undo a tone: type the same tone key again
        var engine = Engine()
        typeInto(&engine, keys: "vi")
        _ = engine.processKey(key: "r", shift: false) // hỏi on i → vỉ
        _ = engine.processKey(key: "r", shift: false) // toggle → removes hỏi, appends literal 'r' → "vir"
        // Now buffer = [v, i(ngang), r(literal)]
        // This doesn't cleanly get to "việt" either — toggle appends literal 'r'
        // User would need backspace after toggle to remove the 'r', then retype
    }

    func test_D4_toggle_undo_wrong_tone() {
        // User types "as" (á), realizes wrong tone, types "s" again to toggle → "as"
        // Then types "f" for correct tone → "af"... wait, after toggle "as" the buffer has [a, s]
        // Actually after toggle: buffer has [a(ngang), s(literal)]
        // Then 'f' on buffer with vowel 'a' → conditional tone → à... but 's' is in buffer
        // Let me trace: "ass" → [a, s] after toggle. Then "f" → buffer has vowel 'a' → huyền
        // buffer[0].tone = huyen → "às"
        var engine = Engine()
        typeInto(&engine, keys: "as") // á
        _ = engine.processKey(key: "s", shift: false) // toggle → "as"
        // Now buffer = [a(ngang), s(literal)], typing 'f':
        let output = engine.processKey(key: "f", shift: false)
        // f is conditionalTone since buffer has vowel → huyền on 'a'
        XCTAssertEqual(output.committedText, "\u{00E0}s") // às
    }

    func test_D4_revert_english_word_midsentence() {
        // User starts typing "sweet" in VN mode:
        // s → literal (no vowel), w → literal (no a/o/u in buffer)
        // Actually: "s" is just literal since no vowel. "w" has no matching vowel. "ee" → ê. "t" → literal.
        // "sweet" → s, w, e(literal), e(modifier→ê), t(literal) → "swêt"
        // User realizes → revert
        var engine = Engine()
        typeInto(&engine, keys: "sweet")
        let output = engine.revert()
        XCTAssertEqual(output.committedText, "sweet") // raw keys
    }

    func test_D4_revert_then_retype() {
        // Type VN, revert, then type VN again
        var engine = Engine()
        typeInto(&engine, keys: "toois") // tối
        _ = engine.revert() // → "toois"

        // After revert, buffer is empty.
        // "laaf": l, a, â(circumflex), ầ(huyền) = "lầ"
        let result = screenText(&engine, keys: "laaf")
        XCTAssertEqual(result, "l\u{1EA7}") // lầ
    }

    // MARK: D5. Uppercase patterns

    func test_D5_uppercase_first_letter() {
        // "Hà Nội" - proper nouns
        XCTAssertEqual(typeSequence("Haf", uppercaseFirst: true), "H\u{00E0}") // Hà
    }

    func test_D5_uppercase_circumflex() {
        // Â, Ê, Ô uppercase
        assertTelex([
            TelexTestCase("Aa",  "\u{00C2}",  "Â uppercase", uppercaseFirst: true),
            TelexTestCase("Ee",  "\u{00CA}",  "Ê uppercase", uppercaseFirst: true),
            TelexTestCase("Oo",  "\u{00D4}",  "Ô uppercase", uppercaseFirst: true),
        ])
    }

    func test_D5_uppercase_horn_breve_stroke() {
        assertTelex([
            TelexTestCase("Ow",  "\u{01A0}",  "Ơ uppercase", uppercaseFirst: true),
            TelexTestCase("Uw",  "\u{01AF}",  "Ư uppercase", uppercaseFirst: true),
            TelexTestCase("Aw",  "\u{0102}",  "Ă uppercase", uppercaseFirst: true),
            TelexTestCase("Dd",  "\u{0110}",  "Đ uppercase", uppercaseFirst: true),
        ])
    }

    func test_D5_uppercase_with_tone() {
        assertTelex([
            TelexTestCase("As",  "\u{00C1}",  "Á uppercase sắc",  uppercaseFirst: true),
            TelexTestCase("Af",  "\u{00C0}",  "À uppercase huyền", uppercaseFirst: true),
            TelexTestCase("Aas", "\u{1EA4}",  "Ấ uppercase â+sắc", uppercaseFirst: true),
            TelexTestCase("Ees", "\u{1EBE}",  "Ế uppercase ê+sắc", uppercaseFirst: true),
        ])
    }

    func test_D5_proper_noun_sentence() {
        // "Hà Nội là thủ đô"
        XCTAssertEqual(typeSequence("Nooji", uppercaseFirst: true), "N\u{1ED9}i") // Nội
    }

    // MARK: D5b. Full paragraph with diverse patterns

    func test_D5b_full_diverse_paragraph() {
        // "Đất nước Việt Nam có hơn 100 triệu dân."
        // Tests: đ, modifier vowels, tones, numbers, punctuation
        let words: [(String, String, Bool)] = [
            ("Ddaats",     "\u{0110}\u{1EA5}t",               true),  // Đất
            ("nuowcs",     "n\u{01B0}\u{1EDB}c",              false), // nước
            ("Vieejt",     "Vi\u{1EC7}t",                     true),  // Việt
            ("Nam",        "Nam",                              true),  // Nam
            ("cos",        "c\u{00F3}",                       false), // có
            ("hown",       "h\u{01A1}n",                      false), // hơn
        ]
        for (keys, expected, uc) in words {
            XCTAssertEqual(typeSequence(keys, uppercaseFirst: uc), expected,
                           "Word: \(keys)")
        }
    }
}
