enum UnicodeMap {

    static func resolve(_ char: VnChar) -> Character {
        let lowercased = lookupLowercase(
            base: char.base,
            modifier: char.modifier,
            tone: char.tone
        )
        guard char.uppercase else { return lowercased }
        return Character(String(lowercased).uppercased())
    }

    static func resolveBuffer(_ buffer: [VnChar]) -> String {
        String(buffer.map { resolve($0) })
    }

    // MARK: - Private

    private static func lookupLowercase(
        base: Character,
        modifier: LetterModifier?,
        tone: Tone
    ) -> Character {
        switch (base, modifier) {
        // a family (18 chars)
        case ("a", nil):
            return toned("a", "\u{00E1}", "\u{00E0}", "\u{1EA3}", "\u{00E3}", "\u{1EA1}", tone)
        case ("a", .circumflex):
            return toned("\u{00E2}", "\u{1EA5}", "\u{1EA7}", "\u{1EA9}", "\u{1EAB}", "\u{1EAD}", tone)
        case ("a", .breve):
            return toned("\u{0103}", "\u{1EAF}", "\u{1EB1}", "\u{1EB3}", "\u{1EB5}", "\u{1EB7}", tone)

        // e family (12 chars)
        case ("e", nil):
            return toned("e", "\u{00E9}", "\u{00E8}", "\u{1EBB}", "\u{1EBD}", "\u{1EB9}", tone)
        case ("e", .circumflex):
            return toned("\u{00EA}", "\u{1EBF}", "\u{1EC1}", "\u{1EC3}", "\u{1EC5}", "\u{1EC7}", tone)

        // i family (6 chars)
        case ("i", nil):
            return toned("i", "\u{00ED}", "\u{00EC}", "\u{1EC9}", "\u{0129}", "\u{1ECB}", tone)

        // o family (18 chars)
        case ("o", nil):
            return toned("o", "\u{00F3}", "\u{00F2}", "\u{1ECF}", "\u{00F5}", "\u{1ECD}", tone)
        case ("o", .circumflex):
            return toned("\u{00F4}", "\u{1ED1}", "\u{1ED3}", "\u{1ED5}", "\u{1ED7}", "\u{1ED9}", tone)
        case ("o", .horn):
            return toned("\u{01A1}", "\u{1EDB}", "\u{1EDD}", "\u{1EDF}", "\u{1EE1}", "\u{1EE3}", tone)

        // u family (12 chars)
        case ("u", nil):
            return toned("u", "\u{00FA}", "\u{00F9}", "\u{1EE7}", "\u{0169}", "\u{1EE5}", tone)
        case ("u", .horn):
            return toned("\u{01B0}", "\u{1EE9}", "\u{1EEB}", "\u{1EED}", "\u{1EEF}", "\u{1EF1}", tone)

        // y family (6 chars)
        case ("y", nil):
            return toned("y", "\u{00FD}", "\u{1EF3}", "\u{1EF7}", "\u{1EF9}", "\u{1EF5}", tone)

        // đ
        case ("d", .stroke):
            return "\u{0111}"

        // No matching Vietnamese character — return base as-is
        default:
            return base
        }
    }

    /// Maps tone to the correct precomposed character.
    /// Parameter order: ngang, sac, huyen, hoi, nga, nang.
    private static func toned(
        _ ngang: Character,
        _ sac: Character,
        _ huyen: Character,
        _ hoi: Character,
        _ nga: Character,
        _ nang: Character,
        _ tone: Tone
    ) -> Character {
        switch tone {
        case .ngang: return ngang
        case .sac:   return sac
        case .huyen: return huyen
        case .hoi:   return hoi
        case .nga:   return nga
        case .nang:  return nang
        }
    }
}
