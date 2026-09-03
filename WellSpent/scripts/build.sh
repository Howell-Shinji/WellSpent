#!/bin/bash
set -euo pipefail

# Build script for the WellSpent macOS app.
# Uses swiftc directly (SPM manifest broken on CLT-only installs).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$APP_DIR"

APP_NAME_DISPLAY="WellSpent"
APP_NAME_INTERNAL="WellSpent"
BUILD_DIR="$APP_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME_DISPLAY.app"
SRC_DIR="$APP_DIR/src"
ICON_DIR="$APP_DIR/icon"
BIN_OUT="$BUILD_DIR/$APP_NAME_INTERNAL"
WELLSPENT_TEMP_ROOT="${TMPDIR:-/tmp}"
MODULE_CACHE_DIR="$(mktemp -d "$WELLSPENT_TEMP_ROOT/wellspent-module-cache.XXXXXX")"

cleanup_module_cache() {
    rm -rf "$MODULE_CACHE_DIR"
}
trap cleanup_module_cache EXIT

echo "→ 清理旧构建产物"
rm -rf "$APP_BUNDLE" "$BIN_OUT"
mkdir -p "$BUILD_DIR"

echo "→ swiftc 编译 (release)"

# Prefer the stable 15.4 SDK when it is installed. Some beta Command Line Tools
# expose a default SDK whose Swift module version does not match their compiler.
if SDK_PATH=$(xcrun --sdk macosx15.4 --show-sdk-path 2>/dev/null); then
    :
else
    SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
fi

SOURCES=(
    "$SRC_DIR/Todo.swift"
    "$SRC_DIR/TodoStore.swift"
    "$SRC_DIR/TokyoNightTheme.swift"
    "$SRC_DIR/CompletionToggle.swift"
    "$SRC_DIR/TodoRow.swift"
    "$SRC_DIR/ContentView.swift"
    "$SRC_DIR/App.swift"
)

xcrun swiftc \
    -O \
    -target arm64-apple-macos13.0 \
    -sdk "$SDK_PATH" \
    -module-cache-path "$MODULE_CACHE_DIR" \
    -framework AppKit \
    -framework SwiftUI \
    -framework Foundation \
    -framework Combine \
    -o "$BIN_OUT" \
    "${SOURCES[@]}"

echo "→ 组装 .app bundle"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_OUT" "$APP_BUNDLE/Contents/MacOS/$APP_NAME_INTERNAL"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME_INTERNAL"

cp "$ICON_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$ICON_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

echo ""
echo "✓ 构建完成: $APP_BUNDLE"
echo "  启动: open \"$APP_BUNDLE\""
