#!/bin/bash
# Sinh Everkey/AppIcon.icns từ make-icon.swift (vẽ trực tiếp bằng AppKit, không cần lib ngoài).
# Render từng kích thước riêng cho sắc nét, rồi gộp bằng iconutil.
set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
SWIFT="$DIR/scripts/make-icon.swift"
ICONSET="$(mktemp -d)/AppIcon.iconset"
OUT="$DIR/Everkey/AppIcon.icns"
mkdir -p "$ICONSET"

render() { # <size> <filename>
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
    swift "$SWIFT" "$ICONSET/$2" "$1" >/dev/null
}

render 16   icon_16x16.png
render 32   icon_16x16@2x.png
render 32   icon_32x32.png
render 64   icon_32x32@2x.png
render 128  icon_128x128.png
render 256  icon_128x128@2x.png
render 256  icon_256x256.png
render 512  icon_256x256@2x.png
render 512  icon_512x512.png
render 1024 icon_512x512@2x.png

iconutil -c icns "$ICONSET" -o "$OUT"
rm -rf "$(dirname "$ICONSET")"
echo "✅ Đã tạo $OUT"
