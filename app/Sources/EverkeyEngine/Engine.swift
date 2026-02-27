struct Engine {
    private(set) var buffer: [VnChar] = []
    private var rawKeys: [Character] = []
    private var active: Bool = true

    init() {}

    mutating func processKey(key: Character, shift: Bool) -> EngineOutput {
        guard active else {
            return EngineOutput(backspaceCount: 0, committedText: String(key))
        }

        let previousLength = buffer.count
        let action = KeyAction.classify(key: key, buffer: buffer)

        switch action {
        case .literal(let char):
            rawKeys.append(key)
            handleLiteral(char, shift: shift)
        case .conditionalModifier(let modifier):
            rawKeys.append(key)
            handleModifier(modifier, key: key)
        case .conditionalTone(let tone):
            rawKeys.append(key)
            handleTone(tone, key: key)
        case .removeTone:
            rawKeys.append(key)
            handleRemoveTone()
        case .wordBreak:
            reset()
            return EngineOutput(backspaceCount: 0, committedText: String(key))
        case .backspace:
            rawKeys.removeLast(min(1, rawKeys.count))
            handleBackspace()
        }

        let committedText = UnicodeMap.resolveBuffer(buffer)
        return EngineOutput(backspaceCount: previousLength, committedText: committedText)
    }

    mutating func setActive(_ active: Bool) {
        self.active = active
        if !active { reset() }
    }

    /// Revert diacritics: output the raw keystrokes instead of Vietnamese text.
    /// Called by platform layer when user triggers revert (e.g. double-shift).
    mutating func revert() -> EngineOutput {
        let displayedLength = buffer.count
        let raw = String(rawKeys)
        reset()
        return EngineOutput(backspaceCount: displayedLength, committedText: raw)
    }

    mutating func reset() {
        buffer.removeAll()
        rawKeys.removeAll()
    }

    // MARK: - Handlers

    private mutating func handleLiteral(_ char: Character, shift: Bool) {
        let lower = Character(char.lowercased())
        buffer.append(VnChar(base: lower, uppercase: shift))
    }

    private mutating func handleModifier(_ modifier: LetterModifier, key: Character) {
        guard !buffer.isEmpty else { return }
        let lowerKey = Character(key.lowercased())

        // Stroke (đ): applies to last char, toggle if already applied
        if modifier == .stroke {
            let lastIndex = buffer.count - 1
            if buffer[lastIndex].modifier == .stroke {
                buffer[lastIndex].modifier = nil
                buffer.append(VnChar(base: lowerKey, uppercase: false))
            } else {
                buffer[lastIndex].modifier = modifier
            }
            return
        }

        let bases = modifierTargetBases(modifier)

        // Scan backwards for last vowel with matching base
        guard let targetIndex = buffer.indices.reversed().first(where: {
            bases.contains(buffer[$0].base) && buffer[$0].isVowel
        }) else { return }

        if buffer[targetIndex].modifier == modifier {
            // Same modifier already applied → undo: remove modifier, append key as literal
            buffer[targetIndex].modifier = nil
            buffer.append(VnChar(base: lowerKey, uppercase: false))
        } else {
            buffer[targetIndex].modifier = modifier
            relocateToneIfNeeded()
        }
    }

    private func modifierTargetBases(_ modifier: LetterModifier) -> [Character] {
        switch modifier {
        case .circumflex: return ["a", "e", "o"]
        case .breve: return ["a"]
        case .horn: return ["o", "u"]
        case .stroke: return ["d"]
        }
    }

    /// After applying a modifier, the tone may need to move.
    /// Modified vowels have priority for tone placement.
    private mutating func relocateToneIfNeeded() {
        guard let currentToneIndex = buffer.indices.first(where: {
            buffer[$0].isVowel && buffer[$0].tone != .ngang
        }) else { return }

        guard let correctIndex = findToneTarget() else { return }

        if currentToneIndex != correctIndex {
            let tone = buffer[currentToneIndex].tone
            buffer[currentToneIndex].tone = .ngang
            buffer[correctIndex].tone = tone
        }
    }

    private mutating func handleTone(_ tone: Tone, key: Character) {
        guard let targetIndex = findToneTarget() else { return }
        if buffer[targetIndex].tone == tone {
            // Same tone already applied → undo: remove tone, append key as literal
            buffer[targetIndex].tone = .ngang
            buffer.append(VnChar(base: Character(key.lowercased()), uppercase: false))
        } else {
            buffer[targetIndex].tone = tone
        }
    }

    private mutating func handleRemoveTone() {
        for i in buffer.indices {
            buffer[i].tone = .ngang
        }
    }

    /// Find the vowel that should receive the tone.
    /// Rules:
    /// 1. Vowel with modifier (circumflex/horn/breve) gets priority
    /// 2. Single vowel → tone on it
    /// 3. Diphthong without coda → tone on first vowel
    /// 4. Diphthong with coda → tone on second vowel
    /// 5. Triple vowel → tone on middle vowel
    private func findToneTarget() -> Int? {
        let vowelIndices = buffer.indices.filter { buffer[$0].isVowel }
        guard !vowelIndices.isEmpty else { return nil }

        // Rule 1: modified vowel gets priority
        if let modified = vowelIndices.first(where: { buffer[$0].modifier != nil }) {
            return modified
        }

        // Rule 2: single vowel
        if vowelIndices.count == 1 {
            return vowelIndices[0]
        }

        // Rule 5: triple vowel → middle
        if vowelIndices.count >= 3 {
            return vowelIndices[1]
        }

        // Rules 3-4: diphthong
        let lastVowelIndex = vowelIndices.last!
        let hasCoda = lastVowelIndex < buffer.count - 1

        return hasCoda ? vowelIndices[1] : vowelIndices[0]
    }

    private mutating func handleBackspace() {
        if !buffer.isEmpty {
            buffer.removeLast()
        }
    }
}
