#!/bin/bash
set -euo pipefail

# 打包 .app 为可分发的 DMG 安装包
# 用法：./WellSpent/scripts/package-dmg.sh [版本号]  默认 1.0.0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="WellSpent"
VERSION="${1:-1.0.0}"
BUILD_DIR="$APP_DIR/build"

APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
STAGING="$BUILD_DIR/dmg-staging"
DMG_FINAL="$BUILD_DIR/$APP_NAME-$VERSION.dmg"
DMG_RW="$BUILD_DIR/$APP_NAME-rw.dmg"
VOL_NAME="$APP_NAME $VERSION"

[ -d "$APP_BUNDLE" ] || { echo "✗ .app 不存在: $APP_BUNDLE，先运行 $SCRIPT_DIR/build.sh"; exit 1; }

echo "→ 清理旧 DMG"
rm -rf "$STAGING" "$DMG_FINAL" "$DMG_RW"
mkdir -p "$STAGING"

echo "→ 准备 staging 内容"
cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "→ 创建可写 DMG (UDRW)"
hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$STAGING" \
    -fs HFS+ \
    -format UDRW \
    -ov \
    "$DMG_RW" > /dev/null

echo "→ 挂载并美化窗口"
MOUNT_DIR=$(mktemp -d)
hdiutil attach -nobrowse -readwrite -mountpoint "$MOUNT_DIR" "$DMG_RW" > /dev/null

# 用 AppleScript 设置 Finder 窗口布局（若 AppleScript 被拒绝则跳过）
osascript <<EOF 2>/dev/null || echo "  (Finder 布局跳过：需要 Accessibility 权限)"
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 200, 700, 500}
        set opts to the icon view options of container window
        set arrangement of opts to not arranged
        set icon size of opts to 96
        set position of item "$APP_NAME.app" of container window to {130, 140}
        set position of item "Applications" of container window to {370, 140}
        update without registering applications
        close
    end tell
end tell
EOF

sync
hdiutil detach "$MOUNT_DIR" > /dev/null

echo "→ 压缩为只读 DMG (UDZO)"
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL" -ov > /dev/null

echo "→ 清理临时文件"
rm -rf "$STAGING" "$DMG_RW"
rmdir "$MOUNT_DIR" 2>/dev/null || true

SIZE=$(du -h "$DMG_FINAL" | cut -f1)
echo ""
echo "✓ DMG 已生成: $DMG_FINAL"
echo "  大小: $SIZE"
echo "  安装：双击打开，把 $APP_NAME.app 拖进 Applications 即可"
echo ""
echo "  ⚠️  未代码签名 — 其他人首次打开会被 Gatekeeper 拦"
echo "      解决：右键点 app → 选「打开」→ 弹窗里再次「打开」"
