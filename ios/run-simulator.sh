#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build"
APP_PATH="$BUILD_DIR/Products/Debug-iphonesimulator/Pacor.app"
SIM_ID="${SIM_ID:-AA77AA6B-BD19-4792-83FD-0DD345BC1491}"

echo "Building Pacor..."
xcodebuild \
  -project "$ROOT/Pacor.xcodeproj" \
  -target Pacor \
  -configuration Debug \
  -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=YES \
  ARCHS=arm64 \
  SYMROOT="$BUILD_DIR/Products" \
  OBJROOT="$BUILD_DIR/Intermediates" \
  build

echo "Booting simulator $SIM_ID..."
xcrun simctl boot "$SIM_ID" 2>/dev/null || true

echo "Installing app..."
xcrun simctl install "$SIM_ID" "$APP_PATH"

echo "Launching Pacor..."
xcrun simctl launch "$SIM_ID" tr.abapnews.pacor

open -a Simulator
