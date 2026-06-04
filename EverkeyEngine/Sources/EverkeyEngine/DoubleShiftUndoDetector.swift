/// Phát hiện thao tác "nhấn đồng thời Shift trái + Shift phải" để dùng làm phím tắt hoàn tác.
///
/// Tầng platform đọc trạng thái từng phím Shift (qua device-dependent flag của macOS) rồi đẩy
/// vào đây mỗi khi modifier thay đổi, đồng thời báo mỗi lần có phím chữ được gõ. Detector chỉ
/// coi là cử chỉ undo khi cả hai Shift cùng được giữ trong một thao tác **biệt lập** — không gõ
/// phím chữ nào trong lúc giữ Shift.
///
/// Vì sao cần điều kiện biệt lập: người gõ nhanh hay "gối" hai phím Shift khi gõ liên tiếp chữ
/// hoa (đang giữ Shift này đã nhấn Shift kia), khiến cả hai bit cùng bật trong chốc lát. Nếu chỉ
/// dựa vào "cả hai cùng bật" thì undo sẽ kích hoạt nhầm giữa lúc đang gõ — và vì undo chạy trên
/// main thread song song với việc gõ trên tap thread, nó còn làm hỏng trạng thái engine. Yêu cầu
/// "không gõ chữ trong lúc giữ Shift" loại bỏ cả hai vấn đề: gõ chữ hoa không bao giờ kích hoạt
/// undo, và undo chỉ chạy đúng lúc người dùng không gõ.
public struct DoubleShiftUndoDetector {
    /// Sẵn sàng kích hoạt cho lần "cả hai Shift cùng giữ" kế tiếp.
    private var readyToTrigger = true
    /// Có phím chữ nào được gõ kể từ khi bắt đầu giữ Shift trong thao tác hiện tại không.
    private var typedWhileShiftHeld = false
    /// Hiện đang giữ ít nhất một phím Shift.
    private var anyShiftHeld = false

    public init() {}

    /// Báo có một phím chữ vừa được gõ — chỉ tính là "gõ trong lúc giữ Shift" nếu đang giữ Shift.
    public mutating func noteKeyDown() {
        if anyShiftHeld { typedWhileShiftHeld = true }
    }

    /// Trả về `true` đúng một lần khi cử chỉ hai Shift biệt lập vừa hoàn tất.
    public mutating func update(leftShiftDown: Bool, rightShiftDown: Bool) -> Bool {
        let bothShiftsHeld = leftShiftDown && rightShiftDown
        anyShiftHeld = leftShiftDown || rightShiftDown

        if !anyShiftHeld { typedWhileShiftHeld = false }  // nhả hết Shift → bắt đầu thao tác sạch

        guard bothShiftsHeld else {
            readyToTrigger = true
            return false
        }
        guard readyToTrigger, !typedWhileShiftHeld else { return false }
        readyToTrigger = false
        return true
    }
}
