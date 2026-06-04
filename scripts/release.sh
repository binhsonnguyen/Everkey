#!/bin/bash
# Đóng bản phát hành Everkey: build Release → ký self-signed → tạo .dmg trong dist/.
# Yêu cầu: đã chạy `bash scripts/setup-signing.sh` một lần để có cert.
#
# Bản .dmg này KHÔNG notarize → người dùng phải "Open Anyway" một lần lúc cài đầu
# (System Settings → Privacy & Security). Nhưng các bản update sau giữ nguyên quyền
# Accessibility nhờ ký cùng self-signed cert.
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SIGN_DIR="$HOME/.everkey-signing"
KC="$SIGN_DIR/everkey-signing.keychain-db"
PW_FILE="$SIGN_DIR/keychain-password"
CERT_NAME="Everkey Self-Signed"
BUNDLE_ID="com.everkey.app"
DIST="$PROJECT_DIR/dist"
DERIVED="$PROJECT_DIR/.build-release"

[ -f "$PW_FILE" ] || { echo "❌ Chưa có cert phát hành. Chạy trước: bash scripts/setup-signing.sh"; exit 1; }
PW="$(cat "$PW_FILE")"

VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PROJECT_DIR/Everkey/Info.plist")"

echo "→ Build Release v$VERSION (không phụ thuộc cert Apple)..."
rm -rf "$DERIVED"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project "$PROJECT_DIR/Everkey.xcodeproj" \
  -scheme Everkey -configuration Release \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" \
  build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | grep -v "^note:"

APP="$DERIVED/Build/Products/Release/Everkey.app"
[ -d "$APP" ] || { echo "❌ Build thất bại — không thấy $APP"; exit 1; }

echo "→ Ký self-signed (danh tính phát hành cố định)..."
security unlock-keychain -p "$PW" "$KC"
# codesign tìm identity qua search list → tạm thêm keychain phát hành vào, ký xong khôi phục
ORIG_KEYCHAINS="$(security list-keychains -d user | sed 's/"//g' | xargs)"
restore_keychains() { security list-keychains -d user -s $ORIG_KEYCHAINS; }
trap restore_keychains EXIT
security list-keychains -d user -s "$KC" $ORIG_KEYCHAINS
codesign --force --sign "$CERT_NAME" --identifier "$BUNDLE_ID" \
  --keychain "$KC" --timestamp=none "$APP"
restore_keychains; trap - EXIT

echo "→ Kiểm tra chữ ký..."
codesign --verify --verbose "$APP"
echo -n "   "; codesign -d -r- "$APP" 2>&1 | grep designated

echo "→ Đóng .dmg..."
mkdir -p "$DIST"
DMG="$DIST/Everkey-$VERSION.dmg"
rm -f "$DMG"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Everkey $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo ""
echo "✅ Xong: $DMG"
echo "   Upload file này lên GitHub Release (tag v$VERSION)."
