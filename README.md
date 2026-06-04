<div align="center">

<img src="docs/icon.png" width="128" alt="Everkey" />

# Everkey

Bộ gõ tiếng Việt gọn nhẹ cho macOS — kiểu gõ Telex, chạy ở thanh menu.

</div>

---

## Tính năng

- ⌨️ **Gõ Telex** tiếng Việt với kiểm tra chính tả và tự khôi phục.
- 🔄 **Bật/tắt nhanh** bằng phím tắt (mặc định **Ctrl + Space**).
- ↩️ **Hoàn tác** từ vừa gõ (tùy chọn): bằng phím Esc, phím tắt tự chọn, hoặc nhấn **Shift trái + Shift phải**.
- 🚀 **Khởi động cùng hệ thống** (tùy chọn).
- 🪶 Nhẹ, chạy nền ở thanh menu, không chiếm Dock.

> Yêu cầu: **macOS 12.0 trở lên** (Apple Silicon & Intel).

## Cài đặt

1. Tải `Everkey-x.y.z.dmg` ở mục [Releases](../../releases).
2. Mở `.dmg`, kéo **Everkey** vào thư mục **Applications**.
3. Mở Everkey lần đầu — macOS sẽ chặn vì app chưa ký bởi Apple (xem mục dưới).
4. Cấp quyền **Accessibility** khi được hỏi (bắt buộc để bộ gõ hoạt động).

### Mở app lần đầu (qua cửa Gatekeeper)

Everkey không trả phí Apple Developer nên macOS sẽ báo *"Apple could not verify…"*.
Cách mở (macOS 15 Sequoia / macOS 26 trở lên):

1. Bấm **Done** ở hộp thoại cảnh báo.
2. Vào **System Settings → Privacy & Security**, kéo xuống mục **Security**.
3. Bấm **Open Anyway** bên cạnh dòng "Everkey was blocked", nhập mật khẩu admin.
4. Mở lại Everkey — từ giờ chạy bình thường.

> Chỉ cần làm **một lần** lúc cài đầu. Các bản cập nhật sau **không** phải làm lại,
> và quyền Accessibility cũng **được giữ nguyên** qua các bản cập nhật.

### Cấp quyền Accessibility

**System Settings → Privacy & Security → Accessibility** → bật công tắc **Everkey**.
Bộ gõ cần quyền này để đọc/sửa phím gõ toàn hệ thống.

## Sử dụng

- **Ctrl + Space**: bật/tắt gõ tiếng Việt (đổi được trong cài đặt).
- Nhấp **biểu tượng bàn phím** trên thanh menu để mở menu: bật/tắt, mở Cài đặt, thoát.
- Trong **Cài đặt**: đổi phím tắt, bật hoàn tác, bật khởi động cùng hệ thống.

## Build từ mã nguồn

Cần [XcodeGen](https://github.com/yonaskolb/XcodeGen) và Xcode.

```bash
bash scripts/setup.sh     # sinh Everkey.xcodeproj từ project.yml (chạy 1 lần)
bash scripts/dev.sh       # build + chạy bản dev
```

Chạy test của engine:

```bash
cd EverkeyEngine && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

## Đóng bản phát hành (cho maintainer)

```bash
bash scripts/make-icon.sh        # (khi cần) sinh lại Everkey/AppIcon.icns
bash scripts/setup-signing.sh    # tạo cert self-signed cố định — CHẠY MỘT LẦN
bash scripts/release.sh          # build Release → ký → dist/Everkey-<ver>.dmg
```

> ⚠️ Cert phát hành nằm ở `~/.everkey-signing/` — **hãy sao lưu**. Mất nó thì các bản
> cập nhật sau sẽ bị macOS coi là app khác, người dùng phải cấp lại quyền từ đầu.

## Giấy phép

Mã nguồn Everkey: [MIT](LICENSE).

Engine xử lý tiếng Việt lấy từ **XKey** (MIT), vốn là bản port của **OpenKey** (GPL).
Xem [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
