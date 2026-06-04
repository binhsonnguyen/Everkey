<div align="center">

<img src="assets/icon.png" width="128" alt="Everkey" />

# Everkey

Bộ gõ tiếng Việt cho macOS — đơn giản, hoạt động được.

</div>

---

## Tính năng

- ⌨️ Bộ gõ tiếng Việt hoạt động được.
- Chỉ có **một kiểu gõ duy nhất: Simple Telex**.
- ↩️ Cho phép **hoàn tác bằng 2 phím Shift** (Shift trái + Shift phải).

> Yêu cầu: macOS 12.0 trở lên (Apple Silicon & Intel).

## Cài đặt

**Homebrew:**

```bash
brew install --cask --no-quarantine binhsonnguyen/everkey/everkey
```

**Hoặc tải trực tiếp:** lấy file `.dmg` mới nhất ở trang [Releases](../../releases),
mở ra rồi kéo **Everkey** vào thư mục **Applications**.

### Mở app lần đầu

Everkey không ký bởi Apple nên macOS sẽ chặn lần đầu. Mở bằng:

> **System Settings → Privacy & Security → Security → Open Anyway**

(Cài bằng Homebrew với `--no-quarantine` thì bỏ qua được bước này.)

### Cấp quyền

Bật Everkey trong **System Settings → Privacy & Security → Accessibility**.
Bộ gõ cần quyền này để hoạt động.

## Build từ nguồn

Cần [XcodeGen](https://github.com/yonaskolb/XcodeGen) và Xcode.

```bash
bash scripts/setup.sh     # sinh Everkey.xcodeproj (chạy 1 lần)
bash scripts/dev.sh       # build + chạy bản dev
```

## Giấy phép

Mã nguồn Everkey: [MIT](LICENSE).

Engine xử lý tiếng Việt lấy từ **XKey** ([MIT](https://github.com/xmannv/xkey)),
với lời cảm ơn tới **OpenKey** và **UniKey**. Chi tiết: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
