#!/bin/bash
# Generate Everkey.xcodeproj from project.yml (requires xcodegen)
set -e
cd "$(dirname "$0")/.."
xcodegen generate
echo "✅ Everkey.xcodeproj generated. Open: open Everkey.xcodeproj"
