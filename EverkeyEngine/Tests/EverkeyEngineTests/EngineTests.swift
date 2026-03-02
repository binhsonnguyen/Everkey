import XCTest
@testable import EverkeyEngine

final class EngineTests: XCTestCase {

    func test_single_literal_character() {
        var engine = Engine()
        let output = engine.processKey(key: "a", shift: false)
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "a"))
    }

    func test_multiple_literal_characters() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        let output = engine.processKey(key: "b", shift: false)
        // Incremental: "a"→"ab", common prefix "a", bs:0, text:"b"
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "b"))
    }

    func test_uppercase_literal() {
        var engine = Engine()
        let output = engine.processKey(key: "A", shift: true)
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "A"))
    }

    // MARK: - Modifier

    func test_aa_produces_circumflex_a() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        let output = engine.processKey(key: "a", shift: false)
        XCTAssertEqual(output.committedText, "\u{00E2}") // â
    }

    func test_ee_produces_circumflex_e() {
        var engine = Engine()
        _ = engine.processKey(key: "e", shift: false)
        let output = engine.processKey(key: "e", shift: false)
        XCTAssertEqual(output.committedText, "\u{00EA}") // ê
    }

    func test_oo_produces_circumflex_o() {
        var engine = Engine()
        _ = engine.processKey(key: "o", shift: false)
        let output = engine.processKey(key: "o", shift: false)
        XCTAssertEqual(output.committedText, "\u{00F4}") // ô
    }

    func test_aw_produces_breve_a() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        let output = engine.processKey(key: "w", shift: false)
        XCTAssertEqual(output.committedText, "\u{0103}") // ă
    }

    func test_ow_produces_horn_o() {
        var engine = Engine()
        _ = engine.processKey(key: "o", shift: false)
        let output = engine.processKey(key: "w", shift: false)
        XCTAssertEqual(output.committedText, "\u{01A1}") // ơ
    }

    func test_uw_produces_horn_u() {
        var engine = Engine()
        _ = engine.processKey(key: "u", shift: false)
        let output = engine.processKey(key: "w", shift: false)
        XCTAssertEqual(output.committedText, "\u{01B0}") // ư
    }

    func test_dd_produces_stroke_d() {
        var engine = Engine()
        _ = engine.processKey(key: "d", shift: false)
        let output = engine.processKey(key: "d", shift: false)
        XCTAssertEqual(output.committedText, "\u{0111}") // đ
    }

    func test_Aa_produces_uppercase_circumflex() {
        var engine = Engine()
        _ = engine.processKey(key: "A", shift: true)
        let output = engine.processKey(key: "a", shift: false)
        XCTAssertEqual(output.committedText, "\u{00C2}") // Â
    }

    // MARK: - Tone

    func test_as_produces_sac_a() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        let output = engine.processKey(key: "s", shift: false)
        XCTAssertEqual(output.committedText, "\u{00E1}") // á
    }

    func test_af_produces_huyen_a() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        let output = engine.processKey(key: "f", shift: false)
        XCTAssertEqual(output.committedText, "\u{00E0}") // à
    }

    func test_ar_produces_hoi_a() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        let output = engine.processKey(key: "r", shift: false)
        XCTAssertEqual(output.committedText, "\u{1EA3}") // ả
    }

    func test_ax_produces_nga_a() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        let output = engine.processKey(key: "x", shift: false)
        XCTAssertEqual(output.committedText, "\u{00E3}") // ã
    }

    func test_aj_produces_nang_a() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        let output = engine.processKey(key: "j", shift: false)
        XCTAssertEqual(output.committedText, "\u{1EA1}") // ạ
    }

    func test_tone_on_modified_vowel() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        _ = engine.processKey(key: "a", shift: false) // â
        let output = engine.processKey(key: "s", shift: false)
        XCTAssertEqual(output.committedText, "\u{1EA5}") // ấ
    }

    func test_tone_prefers_modified_vowel() {
        var engine = Engine()
        for c in ["v", "i", "e", "e"] { // buffer: v, i, ê
            _ = engine.processKey(key: Character(c), shift: false)
        }
        let output = engine.processKey(key: "j", shift: false)
        // Incremental: "viê"→"việ", common prefix "vi", bs:1, text:"ệ"
        XCTAssertEqual(output.committedText, "\u{1EC7}") // ệ
    }

    func test_remove_tone_with_z() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        _ = engine.processKey(key: "s", shift: false) // á
        let output = engine.processKey(key: "z", shift: false)
        XCTAssertEqual(output.committedText, "a")
    }

    func test_replace_tone() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        _ = engine.processKey(key: "s", shift: false) // á
        let output = engine.processKey(key: "f", shift: false) // á → à
        XCTAssertEqual(output.committedText, "\u{00E0}") // à
    }

    func test_tone_key_without_vowel_is_literal() {
        var engine = Engine()
        _ = engine.processKey(key: "t", shift: false)
        let output = engine.processKey(key: "s", shift: false)
        // Incremental: "t"→"ts", common prefix "t", only "s" appended
        XCTAssertEqual(output.committedText, "s")
    }

    // MARK: - End-to-end

    func test_Vieejt_produces_Viet() {
        XCTAssertEqual(typeWord("vieejt"), "Vi\u{1EC7}t") // Việt
    }

    func test_xin_chaof_resets_at_space() {
        // Space is wordBreak → resets engine, then "chaof" → "chào"
        XCTAssertEqual(typeWord("xin chaof", uppercase: false), "xin ch\u{00E0}o")
    }

    func test_backspace_pops_buffer() {
        var engine = Engine()
        for c in "vi" {
            _ = engine.processKey(key: c, shift: false)
        }
        let output = engine.processKey(key: "\u{08}", shift: false) // backspace
        // Incremental: "vi"→"v", common prefix "v", bs:1, text:""
        XCTAssertEqual(output, EngineOutput(backspaceCount: 1, committedText: ""))
    }

    func test_ddeef_produces_dề() {
        XCTAssertEqual(typeWord("ddeef", uppercase: false), "\u{0111}\u{1EC1}") // đề
    }

    // MARK: - Flexible typing order
    // All 6 permutations of (modifier=e, tone=j, coda=t) after "vie"

    func test_flexible_modifier_tone_coda() {
        XCTAssertEqual(typeWord("vieejt"), "Vi\u{1EC7}t")
    }

    func test_flexible_modifier_coda_tone() {
        XCTAssertEqual(typeWord("vieetj"), "Vi\u{1EC7}t")
    }

    func test_flexible_tone_modifier_coda() {
        XCTAssertEqual(typeWord("viejet"), "Vi\u{1EC7}t")
    }

    func test_flexible_tone_coda_modifier() {
        XCTAssertEqual(typeWord("viejte"), "Vi\u{1EC7}t")
    }

    func test_flexible_coda_modifier_tone() {
        XCTAssertEqual(typeWord("vietej"), "Vi\u{1EC7}t")
    }

    func test_flexible_coda_tone_modifier() {
        XCTAssertEqual(typeWord("vietje"), "Vi\u{1EC7}t")
    }

    // MARK: - Advanced tone placement (qu/gi onset, ươ)

    func test_quas_produces_quá() {
        XCTAssertEqual(typeWord("quas", uppercase: false), "qu\u{00E1}")
    }

    func test_gias_produces_giá() {
        XCTAssertEqual(typeWord("gias", uppercase: false), "gi\u{00E1}")
    }

    func test_thuowng_produces_thương() {
        XCTAssertEqual(typeWord("thuowng", uppercase: false), "th\u{01B0}\u{01A1}ng")
    }

    func test_thuowfng_produces_thường() {
        XCTAssertEqual(typeWord("thuowfng", uppercase: false), "th\u{01B0}\u{1EDD}ng")
    }

    // MARK: - Toggle (undo diacritics by repeating key)

    func test_toggle_modifier_aaa_produces_aa() {
        XCTAssertEqual(typeWord("aaa", uppercase: false), "aa")
    }

    func test_toggle_modifier_aww_produces_aw() {
        XCTAssertEqual(typeWord("aww", uppercase: false), "aw")
    }

    func test_toggle_modifier_ddd_produces_dd() {
        XCTAssertEqual(typeWord("ddd", uppercase: false), "dd")
    }

    func test_toggle_tone_ass_produces_as() {
        XCTAssertEqual(typeWord("ass", uppercase: false), "as")
    }

    func test_toggle_tone_aff_produces_af() {
        XCTAssertEqual(typeWord("aff", uppercase: false), "af")
    }

    // MARK: - Word break & edge cases

    func test_number_is_word_break() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        _ = engine.processKey(key: "s", shift: false) // á
        _ = engine.processKey(key: "1", shift: false) // word break
        let output = engine.processKey(key: "b", shift: false)
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "b"))
    }

    func test_inactive_engine_passes_through() {
        var engine = Engine()
        engine.setActive(false)
        _ = engine.processKey(key: "a", shift: false)
        let output = engine.processKey(key: "s", shift: false)
        // No Telex processing: 's' is just 's', not a tone
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "s"))
    }

    // MARK: - Revert diacritics

    func test_revert_undoes_tone() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        _ = engine.processKey(key: "s", shift: false) // á
        let output = engine.revert()
        XCTAssertEqual(output, EngineOutput(backspaceCount: 1, committedText: "as"))
    }

    func test_revert_undoes_modifier() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        _ = engine.processKey(key: "a", shift: false) // â
        let output = engine.revert()
        XCTAssertEqual(output, EngineOutput(backspaceCount: 1, committedText: "aa"))
    }

    func test_revert_complex_word() {
        var engine = Engine()
        for (c, shift) in [("V", true), ("i", false), ("e", false), ("e", false), ("j", false), ("t", false)] {
            _ = engine.processKey(key: Character(c), shift: shift)
        }
        let output = engine.revert()
        // "Việt" is 4 displayed chars, raw keys are "Vieejt"
        XCTAssertEqual(output, EngineOutput(backspaceCount: 4, committedText: "Vieejt"))
    }

    func test_revert_resets_buffer() {
        var engine = Engine()
        _ = engine.processKey(key: "a", shift: false)
        _ = engine.processKey(key: "s", shift: false) // á
        _ = engine.revert() // → "as", buffer reset
        let output = engine.processKey(key: "b", shift: false)
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: "b"))
    }

    func test_revert_empty_buffer() {
        var engine = Engine()
        let output = engine.revert()
        XCTAssertEqual(output, EngineOutput(backspaceCount: 0, committedText: ""))
    }

    // MARK: - Helpers

    private func typeWord(_ keys: String, uppercase firstChar: Bool = true) -> String {
        var engine = Engine()
        var screen = ""
        for (i, c) in keys.enumerated() {
            let shift = (i == 0) && firstChar && c.isLetter
            let output = engine.processKey(key: c, shift: shift)
            screen.removeLast(min(output.backspaceCount, screen.count))
            screen += output.committedText
        }
        return screen
    }
}
