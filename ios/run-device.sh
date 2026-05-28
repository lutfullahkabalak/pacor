#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build-device"
APP_PATH="$BUILD_DIR/Build/Products/Debug-iphoneos/Pacor.app"
TEAM_ID="${TEAM_ID:-NT667YPH5X}"
BUNDLE_ID="tr.abapnews.pacor"

pick_physical_iphone_udid() {
  xcrun xcdevice list 2>/dev/null | python3 -c '
import json, sys

for device in json.load(sys.stdin):
    if device.get("simulator"):
        continue
    if device.get("platform") != "com.apple.platform.iphoneos":
        continue
    if not device.get("available", True):
        continue
    print(device["identifier"])
    break
'
}

pick_devicectl_id() {
  xcrun devicectl list devices --json-output /tmp/pacor-devices.json >/dev/null 2>&1 || return 1
  python3 -c '
import json
data = json.load(open("/tmp/pacor-devices.json"))
for device in data.get("result", {}).get("devices", []):
    state = device.get("connectionProperties", {}).get("transportType", "")
    if device.get("deviceProperties", {}).get("bootState") or state:
        print(device["identifier"])
        break
' 2>/dev/null
}

DEVICE_UDID="${DEVICE_UDID:-$(pick_physical_iphone_udid)}"
DEVICECTL_ID="${DEVICECTL_ID:-$(pick_devicectl_id)}"

if [[ -z "${DEVICE_UDID}" ]]; then
  echo "Fiziksel iPhone bulunamadi."
  echo ""
  echo "Kontrol listesi:"
  echo "  - USB kablo bagli mi?"
  echo "  - iPhone'da 'Bu Bilgisayara Guven' secildi mi?"
  echo "  - Gelistirici Modu acik mi? (Ayarlar > Gizlilik ve Guvenlik)"
  exit 1
fi

echo "iPhone UDID: $DEVICE_UDID"
if [[ -n "${DEVICECTL_ID}" ]]; then
  echo "devicectl ID: $DEVICECTL_ID"
fi
echo "Building Pacor for iPhone..."

set +e
BUILD_LOG="$(mktemp)"
xcodebuild \
  -project "$ROOT/Pacor.xcodeproj" \
  -scheme Pacor \
  -configuration Debug \
  -destination "id=$DEVICE_UDID" \
  -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  build 2>&1 | tee "$BUILD_LOG"
BUILD_STATUS=${PIPESTATUS[0]}
set -e

if [[ "$BUILD_STATUS" -ne 0 ]]; then
  if grep -q "Program License Agreement" "$BUILD_LOG"; then
    echo ""
    echo "Apple Developer sozlesmesi kabul edilmemis:"
    echo "https://developer.apple.com/account"
  elif grep -q "must be installed to run the scheme" "$BUILD_LOG"; then
    echo ""
    echo "iOS platform surumu eksik. Calistirin:"
    echo "  xcodebuild -downloadPlatform iOS"
  elif grep -q "No profiles for" "$BUILD_LOG"; then
    echo ""
    echo "Provisioning basarisiz. Xcode'da bir kez acip Run deneyin:"
    echo "  open $ROOT/Pacor.xcodeproj"
  fi
  rm -f "$BUILD_LOG"
  exit "$BUILD_STATUS"
fi
rm -f "$BUILD_LOG"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build basarili ama app bulunamadi: $APP_PATH"
  exit 1
fi

INSTALL_DEVICE="${DEVICECTL_ID:-$DEVICE_UDID}"
echo "Installing on iPhone..."
xcrun devicectl device install app --device "$INSTALL_DEVICE" "$APP_PATH"
echo "Launching Pacor..."
xcrun devicectl device process launch --device "$INSTALL_DEVICE" "$BUNDLE_ID" || true
echo "Pacor iPhone'a yuklendi."
