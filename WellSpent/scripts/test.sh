#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/wellspent-tests.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT
if SDK_PATH=$(xcrun --sdk macosx15.4 --show-sdk-path 2>/dev/null); then :; else
    SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
fi
THEME="$APP_DIR/src/TokyoNightTheme.swift"
[ -f "$THEME" ] || THEME="$APP_DIR/src/LavenderTheme.swift"
xcrun swiftc -sdk "$SDK_PATH" -module-cache-path "$WORK_DIR/cache" \
    -framework SwiftUI -framework AppKit -framework Foundation -framework Combine \
    "$APP_DIR/src/Todo.swift" "$APP_DIR/src/TodoRepository.swift" \
    "$APP_DIR/src/TodoStore.swift" "$APP_DIR/src/AppearanceMode.swift" \
    "$APP_DIR/src/WindowGeometry.swift" "$THEME" \
    "$APP_DIR/tests/RegressionTests.swift" -o "$WORK_DIR/regression-tests"
"$WORK_DIR/regression-tests"
