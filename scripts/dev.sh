#!/bin/bash
# Build và chạy Everkey từ DerivedData.
# Quyền Accessibility giữ qua mọi lần build nhờ ký bằng chứng chỉ Apple Development ổn định
# (project.yml: DEVELOPMENT_TEAM + CODE_SIGN_IDENTITY). Xem docs/lessons.md bài 8.

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Tìm đường dẫn DerivedData của project này
APP_PATH=$(DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project "$PROJECT_DIR/Everkey.xcodeproj" \
  -scheme Everkey -configuration Debug \
  -showBuildSettings 2>/dev/null \
  | grep "BUILT_PRODUCTS_DIR" | head -1 | awk '{print $3}')"/Everkey.app"

echo "→ Building..."
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project "$PROJECT_DIR/Everkey.xcodeproj" \
  -scheme Everkey -configuration Debug \
  build 2>&1 | grep -E "error:|warning:|Build complete|BUILD SUCCEEDED|BUILD FAILED" | grep -v "^note:"

echo "→ Restarting from: $APP_PATH"
pkill -x Everkey 2>/dev/null || true
sleep 0.5
open "$APP_PATH"
