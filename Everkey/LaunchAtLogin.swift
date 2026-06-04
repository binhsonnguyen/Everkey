import Foundation
import ServiceManagement

/// Quản lý việc Everkey có tự khởi động cùng hệ thống hay không.
///
/// `SMAppService` là nguồn chân lý duy nhất: macOS tự lưu trạng thái đăng ký login item,
/// nên ta KHÔNG nhân đôi trạng thái này vào UserDefaults để tránh lệch giữa app và hệ thống.
/// Mỗi lần mở Bảng điều khiển, controller đọc lại status thật từ hệ thống.
///
/// API chỉ khả dụng từ macOS 13. Trên macOS cũ hơn `isAvailable == false` và UI ẩn toggle.
@MainActor
final class LaunchAtLogin: ObservableObject {
    /// false khi macOS < 13 (SMAppService không có) — UI dùng cờ này để ẩn toggle.
    let isAvailable: Bool

    /// Trạng thái thật theo hệ thống. Chỉ đọc; thay đổi qua `setEnabled(_:)`.
    @Published private(set) var isEnabled: Bool

    init() {
        if #available(macOS 13.0, *) {
            isAvailable = true
            isEnabled = Self.isRegistered
        } else {
            isAvailable = false
            isEnabled = false
        }
    }

    /// Đăng ký hoặc huỷ đăng ký login item, rồi đồng bộ `isEnabled` về trạng thái thật.
    func setEnabled(_ enabled: Bool) {
        guard #available(macOS 13.0, *) else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("[Everkey] Không thể \(enabled ? "đăng ký" : "huỷ") khởi động cùng hệ thống: \(error)")
        }
        // Luôn phản chiếu trạng thái thật sau thao tác — kể cả khi lỗi hoặc hệ thống
        // yêu cầu người dùng phê duyệt thủ công trong Cài đặt.
        isEnabled = Self.isRegistered

        // macOS có thể đăng ký nhưng chờ người dùng bật trong System Settings → mở giúp họ.
        if enabled, SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    /// Đã đăng ký (đang bật hoặc chờ phê duyệt) đều coi là "bật" theo ý định người dùng.
    @available(macOS 13.0, *)
    private static var isRegistered: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval: return true
        default: return false
        }
    }
}
