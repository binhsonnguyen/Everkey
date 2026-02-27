enum KeyAction: Equatable {
    case literal(Character)
    case conditionalTone(Tone)
    case conditionalModifier(LetterModifier)
    case removeTone
    case wordBreak
    case backspace

    static func classify(key: Character, buffer: [VnChar]) -> KeyAction {
        let lower = Character(key.lowercased())

        switch lower {
        // Modifier triggers: scan buffer for matching vowel
        case "a" where buffer.hasVowelWithBase("a"):
            return .conditionalModifier(.circumflex)
        case "e" where buffer.hasVowelWithBase("e"):
            return .conditionalModifier(.circumflex)
        case "o" where buffer.hasVowelWithBase("o"):
            return .conditionalModifier(.circumflex)

        // w → breve (on a) or horn (on o/u)
        case "w" where buffer.hasVowelWithBase("a"):
            return .conditionalModifier(.breve)
        case "w" where buffer.hasVowelWithBase("o") || buffer.hasVowelWithBase("u"):
            return .conditionalModifier(.horn)

        // dd → đ (must be consecutive)
        case "d" where buffer.last?.base == "d" && buffer.last?.modifier == nil:
            return .conditionalModifier(.stroke)

        // Tone keys — only act when buffer has a vowel
        case "s" where buffer.containsVowel:
            return .conditionalTone(.sac)
        case "f" where buffer.containsVowel:
            return .conditionalTone(.huyen)
        case "r" where buffer.containsVowel:
            return .conditionalTone(.hoi)
        case "x" where buffer.containsVowel:
            return .conditionalTone(.nga)
        case "j" where buffer.containsVowel:
            return .conditionalTone(.nang)
        case "z" where buffer.containsVowel:
            return .removeTone

        // Backspace
        case "\u{08}", "\u{7F}":
            return .backspace

        // Word break
        case " ", "\n", "\t":
            return .wordBreak
        case _ where ".,;:!?/\\|<>=+-*&%$#@~`\"'()[]{}".contains(lower):
            return .wordBreak

        // Everything else: literal
        default:
            return .literal(key)
        }
    }
}

extension Array where Element == VnChar {
    var containsVowel: Bool {
        contains { $0.isVowel }
    }

    func hasVowelWithBase(_ base: Character) -> Bool {
        contains { $0.base == base && $0.isVowel }
    }
}
