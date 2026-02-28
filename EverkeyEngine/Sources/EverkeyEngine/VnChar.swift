public struct VnChar: Equatable {
    let base: Character
    var uppercase: Bool
    var modifier: LetterModifier?
    var tone: Tone

    init(
        base: Character,
        uppercase: Bool = false,
        modifier: LetterModifier? = nil,
        tone: Tone = .ngang
    ) {
        self.base = base
        self.uppercase = uppercase
        self.modifier = modifier
        self.tone = tone
    }

    var isVowel: Bool {
        "aeiouy".contains(base)
    }
}
