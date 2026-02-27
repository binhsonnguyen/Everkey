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
