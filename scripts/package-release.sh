#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/magicState.xcodeproj"
SCHEME="magicState"
CONFIGURATION="Release"
APP_NAME="magicState"
DIST_DIR="$ROOT_DIR/dist"
BUILD_ROOT="$DIST_DIR/build"
DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  VERSION="$(
    xcodebuild -project "$PROJECT_PATH" \
      -scheme "$SCHEME" \
      -configuration "$CONFIGURATION" \
      -showBuildSettings 2>/dev/null \
      | awk -F= '/ MARKETING_VERSION / { gsub(/[[:space:]]/, "", $2); print $2; exit }'
  )"
fi

if [[ -z "$VERSION" ]]; then
  echo "error: unable to determine MARKETING_VERSION" >&2
  exit 1
fi

ZIP_NAME="${APP_NAME}-v${VERSION}-macos.zip"
APP_OUTPUT="$DIST_DIR/${APP_NAME}.app"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"

mkdir -p "$DIST_DIR"
rm -rf "$BUILD_ROOT" "$APP_OUTPUT" "$ZIP_PATH"

xcodebuild -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

BUILT_APP="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/${APP_NAME}.app"

if [[ ! -d "$BUILT_APP" ]]; then
  echo "error: built app not found at $BUILT_APP" >&2
  exit 1
fi

cp -R "$BUILT_APP" "$APP_OUTPUT"

(
  cd "$DIST_DIR"
  ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "$ZIP_NAME"
)

echo "Created $ZIP_PATH"
