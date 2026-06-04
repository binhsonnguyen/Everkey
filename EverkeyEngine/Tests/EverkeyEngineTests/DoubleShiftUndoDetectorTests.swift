import XCTest
@testable import EverkeyEngine

final class DoubleShiftUndoDetectorTests: XCTestCase {

    func testTriggersWhenBothShiftsBecomeHeldTogether() {
        var detector = DoubleShiftUndoDetector()
        XCTAssertFalse(detector.update(leftShiftDown: true, rightShiftDown: false),
                       "Một Shift chưa đủ để kích hoạt")
        XCTAssertTrue(detector.update(leftShiftDown: true, rightShiftDown: true),
                      "Khi Shift thứ hai được nhấn, cả hai cùng giữ → kích hoạt undo")
    }

    func testDoesNotRepeatWhileBothShiftsStayHeld() {
        var detector = DoubleShiftUndoDetector()
        _ = detector.update(leftShiftDown: true, rightShiftDown: true)
        XCTAssertFalse(detector.update(leftShiftDown: true, rightShiftDown: true),
                       "Giữ nguyên cả hai Shift không được kích hoạt lặp lại")
    }

    func testReArmsAfterReleaseSoNextDoublePressTriggersAgain() {
        var detector = DoubleShiftUndoDetector()
        _ = detector.update(leftShiftDown: true, rightShiftDown: true)
        _ = detector.update(leftShiftDown: true, rightShiftDown: false) // nhả Shift phải
        XCTAssertTrue(detector.update(leftShiftDown: true, rightShiftDown: true),
                      "Nhấn lại cả hai Shift sau khi nhả → kích hoạt tiếp")
    }

    func testNeverTriggersForASingleShiftAlone() {
        var detector = DoubleShiftUndoDetector()
        XCTAssertFalse(detector.update(leftShiftDown: true, rightShiftDown: false))
        XCTAssertFalse(detector.update(leftShiftDown: false, rightShiftDown: true))
        XCTAssertFalse(detector.update(leftShiftDown: false, rightShiftDown: false))
    }

    func testDoesNotTriggerWhenAKeyWasTypedWhileShiftHeld() {
        // Gõ chữ hoa (giữ Shift + phím) rồi gối sang Shift kia: đây là gõ, không phải cử chỉ undo.
        var detector = DoubleShiftUndoDetector()
        _ = detector.update(leftShiftDown: true, rightShiftDown: false)
        detector.noteKeyDown()
        XCTAssertFalse(detector.update(leftShiftDown: true, rightShiftDown: true),
                       "Có phím chữ gõ trong lúc giữ Shift → không được coi là undo")
    }

    func testTypingWithoutShiftDoesNotDisqualifyTheGesture() {
        // Gõ chữ thường (không Shift) rồi mới thực hiện cử chỉ hai Shift → vẫn kích hoạt.
        var detector = DoubleShiftUndoDetector()
        detector.noteKeyDown()
        _ = detector.update(leftShiftDown: true, rightShiftDown: false)
        XCTAssertTrue(detector.update(leftShiftDown: true, rightShiftDown: true))
    }

    func testGestureWorksAgainAfterShiftsFullyReleasedFollowingTyping() {
        var detector = DoubleShiftUndoDetector()
        _ = detector.update(leftShiftDown: true, rightShiftDown: false)
        detector.noteKeyDown()                                       // gõ chữ hoa
        _ = detector.update(leftShiftDown: false, rightShiftDown: false) // nhả hết Shift → sạch
        _ = detector.update(leftShiftDown: true, rightShiftDown: false)
        XCTAssertTrue(detector.update(leftShiftDown: true, rightShiftDown: true),
                      "Sau khi nhả hết Shift, cử chỉ biệt lập lại kích hoạt được")
    }
}
