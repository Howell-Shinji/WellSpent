#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="WellSpent"
BUILD_DIR="$APP_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
[ -d "$APP_BUNDLE" ] || { echo "请先运行 $SCRIPT_DIR/build.sh"; exit 1; }

BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist")
VERSION="${1:-$BUNDLE_VERSION}"
[ "$VERSION" = "$BUNDLE_VERSION" ] || {
    echo "版本不一致：应用为 $BUNDLE_VERSION，请先更新 Info.plist 并重新构建。"; exit 1;
}
EDITION=$(/usr/libexec/PlistBuddy -c "Print :WellSpentEdition" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true)
EDITION_SUFFIX="${EDITION:+-$EDITION}"
DMG_FINAL="$BUILD_DIR/$APP_NAME$EDITION_SUFFIX-$VERSION.dmg"
VOL_NAME="$APP_NAME${EDITION:+ $EDITION} $VERSION"
STAGING="$(mktemp -d "$BUILD_DIR/dmg-staging.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT

cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGING" \
    -format UDZO -imagekey zlib-level=9 -ov "$DMG_FINAL"
hdiutil verify "$DMG_FINAL"
echo "DMG 已生成：$DMG_FINAL"
echo "双击打开，将 WellSpent.app 拖入 Applications。"
echo "此本地构建未签名、未公证。"
