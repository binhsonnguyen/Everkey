#!/bin/bash
# Tạo self-signed code-signing cert CỐ ĐỊNH cho Everkey — chạy MỘT LẦN.
#
# Cert này là DANH TÍNH phát hành. Mọi bản release ký bằng nó để quyền
# Accessibility của người dùng được GIỮ qua các bản update (đã kiểm chứng:
# DR pin theo cert root, ổn định qua mọi build; xem docs/lessons.md / memory).
#
# ⚠️  SAO LƯU thư mục ~/.everkey-signing. MẤT cert = không thể ký bản update
#     cùng danh tính → người dùng sẽ phải cấp lại quyền từ đầu.
set -e

SIGN_DIR="$HOME/.everkey-signing"
KC="$SIGN_DIR/everkey-signing.keychain-db"
P12="$SIGN_DIR/everkey-signing.p12"
PW_FILE="$SIGN_DIR/keychain-password"
CERT_NAME="Everkey Self-Signed"

if [ -f "$P12" ]; then
  echo "✅ Cert đã tồn tại: $P12"
  echo "   (Bỏ qua — KHÔNG tạo lại để giữ nguyên danh tính phát hành.)"
  exit 0
fi

mkdir -p "$SIGN_DIR"; chmod 700 "$SIGN_DIR"

# mật khẩu ngẫu nhiên cho keychain phát hành
PW="$(openssl rand -base64 24)"
printf '%s' "$PW" > "$PW_FILE"; chmod 600 "$PW_FILE"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# cert + private key, hạn 10 năm, dùng cho code signing
openssl req -x509 -newkey rsa:2048 -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
  -days 3650 -nodes \
  -subj "/CN=$CERT_NAME/O=Everkey" \
  -addext "extendedKeyUsage=critical,codeSigning" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "keyUsage=critical,digitalSignature" 2>/dev/null

# p12 — cờ -legacy để `security` của Apple đọc được (OpenSSL 3 mặc định không tương thích)
openssl pkcs12 -export -legacy -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
  -out "$P12" -passout "pass:$PW" -name "$CERT_NAME"
chmod 600 "$P12"

# keychain riêng (không đụng login keychain) + import + cho codesign dùng không cần popup
security create-keychain -p "$PW" "$KC"
security set-keychain-settings "$KC"            # không tự khoá
security unlock-keychain -p "$PW" "$KC"
security import "$P12" -k "$KC" -P "$PW" -T /usr/bin/codesign -A
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$PW" "$KC" >/dev/null 2>&1

echo "✅ Đã tạo cert phát hành tại: $SIGN_DIR"
echo "   ⚠️  HÃY SAO LƯU thư mục này (vd vào nơi an toàn / mật khẩu manager)."
echo "   Tiếp theo: bash scripts/release.sh"
