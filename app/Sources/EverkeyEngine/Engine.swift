public struct Engine {
    private(set) var buffer: [VnChar] = []
    private var rawKeys: [Character] = []
    private var active: Bool = true
    private var nonVietnamese: Bool = false
    private var detector: NonVietnameseDetecting?

    public init(detector: NonVietnameseDetecting? = nil) {
        self.detector = detector
    }

    public mutating func processKey(key: Character, shift: Bool) -> EngineOutput {
        guard active else {
            return EngineOutput(backspaceCount: 0, committedText: String(key))
        }

        let previousLength = buffer.count
        var action = KeyAction.classify(key: key, buffer: buffer)

        if nonVietnamese {
            switch action {
            case .conditionalTone, .conditionalModifier, .removeTone:
                action = .literal(key)
            default: break
            }
        }

        switch action {
        case .literal(let char):
            rawKeys.append(key)
            handleLiteral(char, shift: shift)
            detectNonVietnameseIfNeeded()
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
            reevaluateNonVietnamese()
        }

        let committedText = UnicodeMap.resolveBuffer(buffer)
        return EngineOutput(backspaceCount: previousLength, committedText: committedText)
    }

    public mutating func setActive(_ active: Bool) {
        self.active = active
        if !active { reset() }
    }

    /// Revert diacritics: output the raw keystrokes instead of Vietnamese text.
    /// Called by platform layer when user triggers revert (e.g. double-shift).
    public mutating func revert() -> EngineOutput {
        let displayedLength = buffer.count
        let raw = String(rawKeys)
        reset()
        return EngineOutput(backspaceCount: displayedLength, committedText: raw)
    }

    public mutating func setDetector(_ detector: NonVietnameseDetecting?) {
        self.detector = detector
        if detector == nil { nonVietnamese = false }
    }

    public mutating func reset() {
        buffer.removeAll()
        rawKeys.removeAll()
        nonVietnamese = false
    }

    // MARK: - Handlers

    private mutating func handleLiteral(_ char: Character, shift: Bool) {
        let lower = Character(char.lowercased())
        buffer.append(VnChar(base: lower, uppercase: shift))
        relocateToneIfNeeded()
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
            // ươ pattern: horn on 'o' also applies to preceding 'u'
            if modifier == .horn && buffer[targetIndex].base == "o"
                && targetIndex > 0
                && buffer[targetIndex - 1].base == "u"
                && buffer[targetIndex - 1].isVowel
                && buffer[targetIndex - 1].modifier == nil {
                buffer[targetIndex - 1].modifier = .horn
            }
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
    /// 1. Filter out onset vowels (u in qu, i in gi)
    /// 2. If exactly one modified vowel → it gets the tone
    /// 3. Otherwise apply positional rules: single → it, diphthong → first/second by coda, triple → middle
    private func findToneTarget() -> Int? {
        let vowelIndices = buffer.indices.filter { buffer[$0].isVowel }
        guard !vowelIndices.isEmpty else { return nil }

        // Filter out onset vowels (qu, gi)
        let nucleusIndices = vowelIndices.filter { !isOnsetVowel(at: $0) }
        guard !nucleusIndices.isEmpty else { return vowelIndices.last }

        // Exactly one modified vowel → it gets the tone
        let modifiedIndices = nucleusIndices.filter { buffer[$0].modifier != nil }
        if modifiedIndices.count == 1 {
            return modifiedIndices[0]
        }

        // Multiple modified vowels → apply positional rules to them
        // Otherwise → apply positional rules to all nucleus vowels
        let pool = modifiedIndices.count > 1 ? modifiedIndices : nucleusIndices

        if pool.count == 1 { return pool[0] }
        if pool.count >= 3 { return pool[1] }

        let lastPoolIndex = pool.last!
        let hasCoda = lastPoolIndex < buffer.count - 1
        return hasCoda ? pool[1] : pool[0]
    }

    /// A vowel is part of the onset if it's 'u' after 'q' or 'i' after 'g'
    /// and there's another vowel after it in the buffer.
    private func isOnsetVowel(at index: Int) -> Bool {
        guard index > 0 else { return false }
        let hasVowelAfter = buffer[(index + 1)...].contains { $0.isVowel }
        guard hasVowelAfter else { return false }

        let prev = buffer[index - 1]
        if buffer[index].base == "u" && prev.base == "q" { return true }
        if buffer[index].base == "i" && prev.base == "g" && prev.modifier == nil { return true }
        return false
    }

    private mutating func detectNonVietnameseIfNeeded() {
        guard !nonVietnamese else { return }
        guard let detector = detector else { return }
        if detector.isNonVietnamese(buffer: buffer) {
            nonVietnamese = true
            if buffer.contains(where: { $0.isVowel }) {
                rebuildBufferFromRawKeys()
            }
        }
    }

    private mutating func rebuildBufferFromRawKeys() {
        buffer = rawKeys.map { char in
            VnChar(base: Character(char.lowercased()), uppercase: char.isUppercase)
        }
    }

    private mutating func reevaluateNonVietnamese() {
        guard let detector = detector else { return }
        nonVietnamese = detector.isNonVietnamese(buffer: buffer)
    }

    private mutating func handleBackspace() {
        if !buffer.isEmpty {
            buffer.removeLast()
        }
    }
}
