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
