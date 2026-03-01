// MARK: - Protocol

public protocol NonVietnameseDetecting {
    func isNonVietnamese(buffer: [VnChar]) -> Bool
}

// MARK: - Consonant Cluster Detector (Method 1)

public struct ConsonantClusterDetector: NonVietnameseDetecting {

    public init() {}

    private static let validOnsets: Set<String> = [
        "ch", "gh", "gi", "kh", "ng", "nh", "ph", "qu", "th", "tr",
        "ngh",
    ]

    public func isNonVietnamese(buffer: [VnChar]) -> Bool {
        let cluster = leadingConsonants(buffer)
        guard cluster.count >= 2 else { return false }
        return !Self.validOnsets.contains(cluster)
    }

    private func leadingConsonants(_ buffer: [VnChar]) -> String {
        var result = ""
        for char in buffer {
            guard !char.isVowel else { break }
            result.append(char.base)
        }
        return result
    }
}

// MARK: - Invalid Coda Detector (Method 2)

public struct InvalidCodaDetector: NonVietnameseDetecting {

    public init() {}

    private static let validCodas: Set<String> = [
        "c", "ch", "m", "n", "ng", "nh", "p", "t",
    ]

    public func isNonVietnamese(buffer: [VnChar]) -> Bool {
        guard let lastVowelIndex = buffer.lastIndex(where: { $0.isVowel }) else { return false }
        let trailing = buffer[(lastVowelIndex + 1)...]
        guard !trailing.isEmpty else { return false }
        let coda = String(trailing.map { $0.base })
        return !Self.validCodas.contains(coda)
    }
}

// MARK: - Invalid Vowel Nuclei Detector (Method 3)

public struct InvalidVowelNucleiDetector: NonVietnameseDetecting {

    public init() {}

    private static let validLength2: Set<String> = [
        "ai", "ao", "au", "ay",
        "eo", "eu",
        "ia", "ie", "iu",
        "oa", "oe", "oi",
        "ua", "ue", "ui", "uo", "uu", "uy",
        "ye",
    ]

    private static let validLength3: Set<String> = [
        "ieu", "yeu",
        "oai", "oay", "oeo",
        "uay", "uoi", "uou",
        "uya", "uye", "uyu",
    ]

    public func isNonVietnamese(buffer: [VnChar]) -> Bool {
        let nucleus = extractVowelNucleus(buffer)
        guard nucleus.count >= 2 else { return false }
        if nucleus.count == 2 { return !Self.validLength2.contains(nucleus) }
        if nucleus.count == 3 { return !Self.validLength3.contains(nucleus) }
        return true
    }

    private func extractVowelNucleus(_ buffer: [VnChar]) -> String {
        guard let firstVowelIndex = buffer.firstIndex(where: { $0.isVowel }) else {
            return ""
        }

        let startIndex = isOnsetVowel(at: firstVowelIndex, in: buffer)
            ? firstVowelIndex + 1
            : firstVowelIndex

        guard startIndex < buffer.count else { return "" }

        var result = ""
        for i in startIndex..<buffer.count {
            guard buffer[i].isVowel else { break }
            result.append(buffer[i].base)
        }
        return result
    }

    private func isOnsetVowel(at index: Int, in buffer: [VnChar]) -> Bool {
        guard index > 0 else { return false }
        let hasVowelAfter = buffer[(index + 1)...].contains { $0.isVowel }
        guard hasVowelAfter else { return false }

        let prev = buffer[index - 1]
        if buffer[index].base == "u" && prev.base == "q" { return true }
        if buffer[index].base == "i" && prev.base == "g" && prev.modifier == nil { return true }
        return false
    }
}

// MARK: - Composite Detector

public struct CompositeDetector: NonVietnameseDetecting {

    private let detectors: [NonVietnameseDetecting]

    public init(_ detectors: [NonVietnameseDetecting]) {
        self.detectors = detectors
    }

    public func isNonVietnamese(buffer: [VnChar]) -> Bool {
        detectors.contains { $0.isNonVietnamese(buffer: buffer) }
    }
}
